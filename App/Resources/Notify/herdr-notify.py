#!/usr/bin/env python3
"""herdr-notify: push notifications for Herdr for iOS, sent from your box.

Follows `hc events` and sends an Apple push to every registered phone when an
agent starts needing you (blocked) or finishes a turn. It talks to Apple
directly over HTTP/2 (curl); nothing goes through a third-party relay.

Files (all under ~/.config/herdr-ios):
  apns.json      {"key_id", "team_id", "bundle_id", "key_path"}  (the app writes it)
  AuthKey.p8     your APNs auth key (chmod 600)
  devices/*.json {"token", "env": "sandbox"|"production", "name"}  (one per phone)
  notify.json    optional: {"on": ["blocked", "done"], "subagents": false}

Usage: herdr-notify.py            run (systemd user service herdr-notify)
       herdr-notify.py --test     send a test notification to every phone
"""
import base64, glob, json, os, re, subprocess, sys, time

HOME = os.path.expanduser("~")
DIR = os.path.join(HOME, ".config", "herdr-ios")
HC = next((p for p in [os.path.join(HOME, ".local/bin/hc"), "/usr/local/bin/hc", "/usr/bin/hc"] if os.path.exists(p)), "hc")
BUSY = {"working", "blocked"}


def log(*a):
    print(time.strftime("%H:%M:%S"), *a, flush=True)


def load(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return default


# ---------------------------------------------------------------- APNs

def b64url(b):
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


def der_to_raw(sig):
    """ECDSA DER signature -> raw r||s (64 bytes) as JWT ES256 wants."""
    i = 2 + (1 if sig[1] & 0x80 else 0)  # skip SEQUENCE header
    rl = sig[i + 1]; r = sig[i + 2:i + 2 + rl]; i += 2 + rl
    sl = sig[i + 1]; s = sig[i + 2:i + 2 + sl]
    return r.lstrip(b"\0").rjust(32, b"\0") + s.lstrip(b"\0").rjust(32, b"\0")


class APNs:
    def __init__(self):
        self.cfg = load(os.path.join(DIR, "apns.json"), None)
        self.jwt, self.jwt_at = None, 0

    def ready(self):
        return bool(self.cfg and all(self.cfg.get(k) for k in ("key_id", "team_id", "bundle_id")))

    def token(self):
        if self.jwt and time.time() - self.jwt_at < 50 * 60:
            return self.jwt
        key_path = os.path.expanduser(self.cfg.get("key_path") or os.path.join(DIR, "AuthKey.p8"))
        head = b64url(json.dumps({"alg": "ES256", "kid": self.cfg["key_id"]}).encode())
        body = b64url(json.dumps({"iss": self.cfg["team_id"], "iat": int(time.time())}).encode())
        msg = f"{head}.{body}".encode()
        try:
            from cryptography.hazmat.primitives import hashes, serialization
            from cryptography.hazmat.primitives.asymmetric import ec
            with open(key_path, "rb") as f:
                key = serialization.load_pem_private_key(f.read(), password=None)
            der = key.sign(msg, ec.ECDSA(hashes.SHA256()))
        except ImportError:
            der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key_path], input=msg,
                                 capture_output=True, check=True).stdout
        self.jwt, self.jwt_at = f"{head}.{body}.{b64url(der_to_raw(der))}", time.time()
        return self.jwt

    def send(self, payload, collapse=None, thread=None):
        devices = [load(p, {}) for p in sorted(glob.glob(os.path.join(DIR, "devices", "*.json")))]
        devices = [d for d in devices if d.get("token")]
        if not devices:
            log("no phones registered yet (open Herdr on the phone while connected)")
            return
        for d in devices:
            host = "api.sandbox.push.apple.com" if d.get("env") != "production" else "api.push.apple.com"
            cmd = ["curl", "-sS", "--http2", "-o", "-", "-w", "\n%{http_code}", "--max-time", "15",
                   "-H", f"authorization: bearer {self.token()}",
                   "-H", f"apns-topic: {self.cfg['bundle_id']}",
                   "-H", "apns-push-type: alert",
                   "-H", f"apns-priority: 10",
                   "--data-binary", "@-", f"https://{host}/3/device/{d['token']}"]
            if collapse:
                cmd[1:1] = ["-H", f"apns-collapse-id: {collapse[:64]}"]
            r = subprocess.run(cmd, input=json.dumps(payload).encode(), capture_output=True)
            out = r.stdout.decode(errors="replace").strip().rsplit("\n", 1)
            code = out[-1] if out else "?"
            if code != "200":
                log(f"push to {d.get('name') or d['token'][:8]} failed: {code} {out[0] if len(out) > 1 else r.stderr.decode()[:200]}")


# ---------------------------------------------------------------- herdr

def label(rec):
    """("Tab name", "space") from herdr's `where` label, else the title."""
    where = (rec.get("labels") or {}).get("where") or ""
    if " / " in where:
        space, tab = where.split(" / ", 1)
        if not tab.isdigit():
            return tab, space
        return (rec.get("title") or tab), space
    return (rec.get("title") or rec.get("address") or "Agent"), None


def dialog(address):
    """The question and options an agent's screen shows while it waits."""
    try:
        screen = subprocess.run([HC, "read", address, "--lines", "0"], capture_output=True, timeout=8).stdout.decode(errors="replace")
    except Exception:
        return None
    lines = [l.strip().strip("│┃|").strip() for l in screen.splitlines()]
    opts, first = [], -1
    for i in range(len(lines) - 1, -1, -1):
        m = re.match(r"^(?:[❯›>]\s*)?(\d)[.)]\s+(.+)$", lines[i])
        if m:
            opts.insert(0, m.group(2)); first = i
        elif opts and lines[i]:
            break
    if not opts:
        return None
    q = []
    i = first - 1
    while i >= 0 and len(q) < 3:
        l = lines[i]
        if not l or set(l) <= set("─━═-╭╮╰╯"):
            if q:
                break
        else:
            q.insert(0, l)
        i -= 1
    return " ".join(q), opts


class Watcher:
    def __init__(self, apns, cfg):
        self.apns, self.cfg = apns, cfg
        self.recs = {}

    def snapshot(self, terminals):
        self.recs = {t["address"]: t for t in terminals if t.get("address")}

    def word(self, rec):
        return ((rec or {}).get("status") or {}).get("state")

    def apply(self, ev):
        addr, typ, data = ev.get("terminal"), ev.get("type"), ev.get("data") or {}
        if typ in ("created", "restarted") and isinstance(data, dict) and data.get("address"):
            self.recs[data["address"]] = data
            return
        rec = self.recs.get(addr)
        if typ == "removed":
            self.recs.pop(addr, None); return
        if rec is None:
            return
        if typ == "status":
            before = self.word(rec)
            rec["status"] = data.get("status")
            self.changed(rec, before, self.word(rec))
        elif typ == "title":
            rec["title"] = data.get("title", rec.get("title"))
        elif typ == "labels":
            rec["labels"] = data.get("labels") or (data.get("record") or {}).get("labels") or rec.get("labels")
        elif typ in ("finished", "lost"):
            rec["state"] = "finished" if typ == "finished" else rec.get("state")

    def changed(self, rec, before, now):
        if before == now or rec.get("state") != "live":
            return
        if rec.get("parent") and not self.cfg.get("subagents", False):
            return
        on = set(self.cfg.get("on", ["blocked", "done"]))
        title, space = label(rec)
        addr = rec["address"]
        info = {"t": addr}
        if now in ("blocked", "error") and before not in ("blocked", "error") and "blocked" in on:
            d = dialog(addr)
            body = (d[0] or "Waiting for your answer") if d else "Waiting for your answer"
            if d and d[1]:
                body += "\n" + "  ·  ".join(f"{i + 1}. {o}" for i, o in enumerate(d[1][:3]))
            self.push(f"{title} needs you", space, body, info, addr, level="time-sensitive")
        elif before in BUSY and now not in BUSY and now is not None and "done" in on:
            self.push(f"{title} finished", space, rec.get("title") or "Ready for you", info, addr)

    def push(self, title, subtitle, body, info, addr, level="active"):
        log(f"push {addr}: {title}")
        alert = {"title": title, "body": body}
        if subtitle:
            alert["subtitle"] = subtitle
        payload = {"aps": {"alert": alert, "sound": "default", "thread-id": addr,
                           "interruption-level": level, "relevance-score": 1.0 if level != "active" else 0.5},
                   "herdr": info}
        self.apns.send(payload, collapse=addr, thread=addr)


def run():
    cfg = load(os.path.join(DIR, "notify.json"), {})
    while True:
        apns = APNs()
        if not apns.ready():
            log("waiting for ~/.config/herdr-ios/apns.json (set up from the app's Settings)")
            time.sleep(30); continue
        w = Watcher(apns, cfg)
        log("following hc events")
        p = subprocess.Popen([HC, "events", "--json"], stdout=subprocess.PIPE, text=True, bufsize=1)
        first = True
        for line in p.stdout:
            try:
                o = json.loads(line)
            except Exception:
                continue
            if first or o.get("method") == "missed" or ("terminals" in o and "seq" in o and "type" not in o):
                first = False
                w.snapshot((o.get("params") or o).get("terminals") or [])
                continue
            ev = o.get("params") if "params" in o else o
            if isinstance(ev, dict) and ev.get("type"):
                try:
                    w.apply(ev)
                except Exception as e:
                    log("event error:", e)
        p.wait()
        log(f"hc events ended ({p.returncode}); restarting in 5s")
        time.sleep(5)


if __name__ == "__main__":
    if "--test" in sys.argv:
        a = APNs()
        if not a.ready():
            sys.exit("not set up: ~/.config/herdr-ios/apns.json missing")
        a.send({"aps": {"alert": {"title": "Herdr", "body": "Notifications from this box work."}, "sound": "default"}})
        print("sent")
    else:
        run()
