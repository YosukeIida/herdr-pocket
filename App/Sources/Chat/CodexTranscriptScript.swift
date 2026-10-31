import Foundation

/// Runs on the box with python3 (read-only). Finds the Codex rollout a terminal's
/// processes have open, then prints it from a byte offset in the same JSON lines as
/// `TranscriptScript`, so `ChatModel` folds both the same way.
///
/// The rollout is found from the open files of the terminal's process tree (lsof, or
/// /proc on Linux), not guessed from the folder: Codex opens it only after the first
/// message, and a Codex attached to a shared app-server has none open itself.
/// Guardian (auto-review) rollouts are skipped by their `thread_source`.
///
/// argv and output: as `TranscriptScript`. Entries come from the rollout's
/// `item_completed` events (UserMessage, AgentMessage, CommandExecution, other items as
/// generic tools) and `task_complete` (turn duration).
enum CodexTranscriptScript {
    static let source = #"""
import sys, os, json, re, subprocess
pid = int(sys.argv[1] or 0)
known = sys.argv[3]
off = int(sys.argv[4])
home = os.path.expanduser('~')

def tree(root):
    kids = {}
    try:
        for line in subprocess.run(['ps', '-axo', 'pid=,ppid='], capture_output=True, text=True).stdout.splitlines():
            a = line.split()
            if len(a) == 2: kids.setdefault(int(a[1]), []).append(int(a[0]))
    except Exception:
        pass
    out, todo = [], [root]
    while todo and len(out) < 256:
        p = todo.pop(); out.append(p); todo.extend(kids.get(p, []))
    return out

def open_paths(pids):
    paths = []
    for p in pids:
        try: paths += [os.readlink('/proc/%d/fd/%s' % (p, fd)) for fd in os.listdir('/proc/%d/fd' % p)]
        except Exception: pass
    if paths or not pids: return paths
    try:
        r = subprocess.run(['lsof', '-Fn', '-p', ','.join(str(p) for p in pids)], capture_output=True, text=True)
        return [l[1:] for l in r.stdout.splitlines() if l.startswith('n')]
    except Exception:
        return []

def meta(path):
    try:
        with open(path, 'rb') as f: d = json.loads(f.readline())
        return (d.get('payload') or {}) if d.get('type') == 'session_meta' else {}
    except Exception:
        return {}

rollouts = set(p for p in open_paths(tree(pid) if pid else []) if re.search(r'/sessions/.+/rollout-[^/]+\.jsonl$', p))
rollouts = [p for p in rollouts if meta(p).get('thread_source', 'user') == 'user']

def by_title():
    # A Codex on the shared app-server holds no rollout itself; its terminal title is
    # "<thread name> | <folder>", and the state DB maps that name and the cwd to the rollout.
    # shortcut: two threads with the same name in the same folder are told apart only by
    # recency; upgrade when Codex exposes the thread id to the terminal.
    try: ctx = json.loads(sys.argv[2])
    except Exception: return []
    if not isinstance(ctx, dict): return []
    title = re.sub(r'^[⠀-⣿\s]+', '', str(ctx.get('title') or ''))
    name = title.rsplit(' | ', 1)[0].strip()
    cwd = str(ctx.get('cwd') or '')
    if not name or not cwd: return []
    import sqlite3, glob
    best = None
    for db in glob.glob(home + '/.codex*/state_*.sqlite'):
        try:
            con = sqlite3.connect('file:%s?mode=ro' % db, uri=True)
            for rp, at in con.execute("select rollout_path, updated_at_ms from threads where name = ? and cwd = ? and coalesce(thread_source, 'user') = 'user' and coalesce(archived, 0) = 0", (name, cwd)):
                if rp and os.path.exists(rp) and (best is None or (at or 0) > best[1]): best = (rp, at or 0)
            con.close()
        except Exception:
            pass
    return [best[0]] if best else []

if not rollouts: rollouts = by_title()
if not rollouts:
    print(json.dumps({'k': 'head', 'session': '', 'why': 'no-session'})); sys.exit(0)
path = max(rollouts, key=lambda f: os.path.getmtime(f))
sid = meta(path).get('id') or os.path.basename(path)[-41:-6]
size = os.path.getsize(path)
fresh = sid != known or off < 0 or off > size
if fresh:
    off = max(0, size - INITIAL)

out = []
def emit(**e): out.append(json.dumps(e, ensure_ascii=False))
def cut(s, n): s = str(s or ''); return s if len(s) <= n else s[:n] + '…'
def short(p):
    p = str(p or '')
    return p.replace(home, '~', 1) if p.startswith(home) else p
def texts(c):
    if isinstance(c, str): return c
    return '\n'.join(b.get('text') or '' for b in c or [] if isinstance(b, dict))
def shell(cmd):
    if isinstance(cmd, list):
        return cmd[2] if len(cmd) >= 3 and cmd[1] in ('-lc', '-c') else ' '.join(str(a) for a in cmd)
    return str(cmd or '')
def summary(i):
    for k in ('path', 'file_path', 'query', 'url', 'server', 'tool', 'name'):
        if i.get(k): return short(i[k]) if 'path' in k else str(i[k]).split('\n')[0]
    return ''

with open(path, 'rb') as f:
    f.seek(off)
    data = f.read(min(size - off, MAXREAD))
if fresh and off > 0:
    nl = data.find(b'\n')
    data = data[nl + 1:] if nl >= 0 else b''
    off += nl + 1 if nl >= 0 else 0
start = off if fresh else -1
end = data.rfind(b'\n')
data = data[:end + 1] if end >= 0 else b''
nxt = off + len(data)

for raw in data.split(b'\n'):
    if not raw or (b'"item_completed"' not in raw and b'"task_complete"' not in raw): continue
    try: d = json.loads(raw)
    except Exception: continue
    if d.get('type') != 'event_msg': continue
    p = d.get('payload') or {}; ts = d.get('timestamp') or ''
    if p.get('type') == 'task_complete':
        emit(k='dur', ms=int(p.get('duration_ms') or 0), ts=ts); continue
    if p.get('type') != 'item_completed': continue
    i = p.get('item') or {}; kind = i.get('type') or ''
    if kind == 'UserMessage':
        # Text sent with hc send arrives wrapped as <hc from="t7">…</hc>; show what was said.
        s = re.sub(r'^<hc from="[^"]*">(.*)</hc>$', r'\1', texts(i.get('content')).strip(), flags=re.S).strip()
        if s: emit(k='user', t=cut(s, 8000), ts=ts)
    elif kind == 'AgentMessage':
        s = texts(i.get('content')).strip()
        if s: emit(k='text', t=cut(s, 20000), ts=ts)
    elif kind == 'CommandExecution':
        cmd = shell(i.get('command'))
        emit(k='tool', id=i.get('id') or '', name='Shell', sum=cut(cmd.split('\n')[0], 200), detail=cut(cmd, 1500), ts=ts)
        code = i.get('exit_code')
        emit(k='result', id=i.get('id') or '', err=code not in (0, None), out=cut(i.get('aggregated_output'), 2000))
    elif kind in ('Reasoning', 'Plan', 'ContextCompaction'):
        if kind == 'ContextCompaction': emit(k='compact', ts=ts)
    elif kind:
        rest = {k: v for k, v in i.items() if k not in ('type', 'id')}
        emit(k='tool', id=i.get('id') or '', name=kind, sum=cut(summary(i), 200), detail=cut(json.dumps(rest, ensure_ascii=False, indent=1), 1200), ts=ts)

print(json.dumps({'k': 'head', 'session': sid, 'path': short(path), 'size': size, 'next': nxt, 'start': start, 'fresh': fresh, 'more': nxt < size}))
print('\n'.join(out))
"""#
        .replacingOccurrences(of: "INITIAL", with: String(TranscriptScript.initialTail))
        .replacingOccurrences(of: "MAXREAD", with: String(TranscriptScript.maxRead))
}
