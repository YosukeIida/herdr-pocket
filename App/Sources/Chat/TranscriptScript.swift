import Foundation

/// Runs on the box with python3 (read-only). Finds the Claude Code session
/// under a terminal's process, then prints the transcript from a byte offset
/// as compact JSON lines, one per entry the chat shows. Transcripts reach
/// hundreds of MB, so the phone only ever reads the tail and then new bytes.
///
/// argv: <terminal pid> <terminal argv JSON> <known session id or ""> <offset, -1 = tail> [<before>]
/// With <before>, reads the window that ends there instead (the part above what the phone has).
/// First line: {"k":"head","session","path","size","next","start","earlier","more"}; then entries:
///   user {t, ts} · note {t} · cmd {t} · compact · text {t} · tool {id, name, sum, detail}
///   result {id, err, out} · dur {ms}
enum TranscriptScript {
    static let initialTail = 16 << 20
    /// Entries sent for a fresh or earlier window: the box reads 16 MiB fast, but sending and laying out all of it is what made Chat slow to open.
    static let keepEntries = 150
    static let maxRead = 16 << 20

    static let source = #"""
import sys, os, json, glob, re
pid = int(sys.argv[1] or 0)
try: targv = json.loads(sys.argv[2])
except Exception: targv = []
known = sys.argv[3]
off = int(sys.argv[4])
home = os.path.expanduser('~')

PS = None
def ppid(p):
    global PS
    try:
        s = open('/proc/%d/stat' % p).read()
        return int(s[s.rindex(')') + 2:].split()[1])
    except Exception:
        pass
    if PS is None:   # macOS and others without /proc: one ps for the whole walk
        PS = {}
        try:
            import subprocess
            for line in subprocess.run(['ps', '-axo', 'pid=,ppid='], capture_output=True, text=True).stdout.splitlines():
                a = line.split()
                if len(a) == 2: PS[int(a[0])] = int(a[1])
        except Exception:
            pass
    return PS.get(p, 0)

def alive(p):
    try:
        os.kill(p, 0); return True
    except PermissionError:
        return True
    except Exception:
        return False

def under(p, root):
    n = 0
    while p > 1 and n < 64:
        if p == root: return True
        p = ppid(p); n += 1
    return False

sid = ''
if pid:
    best = None
    for f in glob.glob(home + '/.claude/sessions/*.json'):
        try: d = json.load(open(f))
        except Exception: continue
        p = int(d.get('pid') or 0)
        if p and alive(p) and under(p, pid):
            if best is None or (d.get('updatedAt') or 0) > (best.get('updatedAt') or 0): best = d
    if best: sid = best.get('sessionId') or ''
if not sid:
    m = re.search(r'(?:--resume|--session-id|-r)[ =]([0-9a-f]{8}-[0-9a-f-]{27})', ' '.join(str(a) for a in targv))
    if m: sid = m.group(1)
if not sid:
    print(json.dumps({'k': 'head', 'session': '', 'why': 'no-session'})); sys.exit(0)

files = glob.glob(home + '/.claude/projects/*/' + sid + '.jsonl')
if not files:
    print(json.dumps({'k': 'head', 'session': sid, 'why': 'no-file'})); sys.exit(0)
path = max(files, key=lambda f: os.path.getmtime(f))
size = os.path.getsize(path)
fresh = sid != known or off < 0 or off > size
end = size
# argv[5], when given: read the window that ends where the loaded part starts ("show earlier").
before = int(sys.argv[5]) if len(sys.argv) > 5 else -1
if before >= 0:
    if sid != known or before > size:
        print(json.dumps({'k': 'head', 'session': sid, 'why': 'moved'})); sys.exit(0)
    end, off, fresh = before, max(0, before - INITIAL), True
elif fresh:
    off = max(0, size - INITIAL)

out = []
at = [0]   # where the record being read starts
def emit(**e): out.append((at[0], json.dumps(e, ensure_ascii=False)))
def cut(s, n): return s if len(s) <= n else s[:n] + '…'
def tag(s, name):
    m = re.search('<%s>(.*?)</%s>' % (name, name), s, re.S)
    return m.group(1).strip() if m else ''
def blocks_text(c):
    if isinstance(c, str): return c
    parts = []
    for b in c or []:
        if isinstance(b, dict):
            if b.get('type') == 'text': parts.append(b.get('text') or '')
            elif b.get('type') == 'image': parts.append('[image]')
    return '\n'.join(parts)
def short(p):
    p = str(p or '')
    return p.replace(home, '~', 1) if p.startswith(home) else p
def summary(name, i):
    if not isinstance(i, dict): return ''
    if name == 'Bash': return i.get('description') or (i.get('command') or '').split('\n')[0]
    for k in ('file_path', 'notebook_path', 'path'):
        if i.get(k): return short(i[k])
    for k in ('pattern', 'query', 'url', 'description', 'skill', 'prompt', 'command'):
        if i.get(k): return str(i[k]).split('\n')[0]
    return ''
def detail(name, i):
    if not isinstance(i, dict): return ''
    if name == 'Bash': return cut(i.get('command') or '', 1500)
    if name in ('Edit', 'MultiEdit'):
        o, n = i.get('old_string') or '', i.get('new_string') or ''
        return cut('- ' + o.replace('\n', '\n- ') + '\n+ ' + n.replace('\n', '\n+ '), 1500)
    if name == 'Write': return cut(i.get('content') or '', 1200)
    if name == 'TodoWrite':
        return '\n'.join(('☑ ' if t.get('status') == 'completed' else '▸ ' if t.get('status') == 'in_progress' else '☐ ') + (t.get('content') or '') for t in i.get('todos') or [])
    try: return cut(json.dumps(i, ensure_ascii=False, indent=1), 1200)
    except Exception: return ''

with open(path, 'rb') as f:
    f.seek(off)
    data = f.read(min(end - off, MAXREAD))
if fresh and off > 0:
    nl = data.find(b'\n')
    data = data[nl + 1:] if nl >= 0 else b''
    off += nl + 1 if nl >= 0 else 0
start = off if fresh else -1
end = data.rfind(b'\n')
read = len(data)
data = data[:end + 1] if end >= 0 else b''
# Waiting for the newline of a record longer than MAXREAD would reread the same window forever.
nxt = off + (read if end < 0 and read >= MAXREAD else len(data))

pos = off
for raw in data.split(b'\n'):
    at[0] = pos; pos += len(raw) + 1
    if not raw or (b'"type":"user"' not in raw and b'"type":"assistant"' not in raw and b'"subtype":"turn_duration"' not in raw and b'"subtype":"compact_boundary"' not in raw):
        continue
    try: d = json.loads(raw)
    except Exception: continue
    if d.get('isSidechain'): continue
    t = d.get('type'); ts = d.get('timestamp') or ''
    if t == 'system':
        if d.get('subtype') == 'turn_duration': emit(k='dur', ms=d.get('durationMs') or 0, ts=ts)
        elif d.get('subtype') == 'compact_boundary': emit(k='compact', ts=ts)
        continue
    m = d.get('message') or {}
    c = m.get('content')
    if t == 'user':
        if isinstance(c, list) and any(isinstance(b, dict) and b.get('type') == 'tool_result' for b in c):
            for b in c:
                if isinstance(b, dict) and b.get('type') == 'tool_result':
                    emit(k='result', id=b.get('tool_use_id') or '', err=bool(b.get('is_error')), out=cut(blocks_text(b.get('content')), 2000))
            continue
        if d.get('isMeta'): continue
        s = blocks_text(c)
        if d.get('isCompactSummary') or s.startswith('This session is being continued from a previous conversation'):
            emit(k='compact', ts=ts); continue
        if s.startswith('<task-notification>'):
            emit(k='note', t=tag(s, 'summary') or 'Background task finished', ts=ts); continue
        if '<command-name>' in s:
            name = tag(s, 'command-name'); args = tag(s, 'command-args')
            emit(k='cmd', t=(name + ' ' + args).strip(), ts=ts); continue
        if s.startswith('<local-command-stdout>') or s.startswith('<local-command-caveat>') or s.startswith('Caveat:'): continue
        s = re.sub(r'<system-reminder>.*?</system-reminder>', '', s, flags=re.S).strip()
        s = re.sub(r'^<hc from="[^"]*">(.*)</hc>$', r'\1', s, flags=re.S).strip()   # text sent with hc send
        if s: emit(k='user', t=cut(s, 8000), ts=ts)
    elif t == 'assistant':
        for b in c if isinstance(c, list) else []:
            if not isinstance(b, dict): continue
            if b.get('type') == 'text' and (b.get('text') or '').strip():
                emit(k='text', t=cut(b['text'], 20000), ts=ts)
            elif b.get('type') == 'tool_use':
                n = b.get('name') or 'Tool'; i = b.get('input') or {}
                emit(k='tool', id=b.get('id') or '', name=n, sum=cut(summary(n, i), 200), detail=detail(n, i), ts=ts)

# A fresh or earlier window sends only its last KEEP entries; the phone asks for the rest with <before> = start.
if fresh and len(out) > KEEP:
    start = out[-KEEP][0]
    out = [o for o in out if o[0] >= start]
if fresh:
    # Long entries could still pass the core's 8 MB stdout cap; drop the oldest until the rest fit in half of it.
    sizes = [len(e.encode('utf-8')) + 1 for _, e in out]
    total, i = sum(sizes), 0
    while i < len(out) - 1 and total > 4000000:
        total -= sizes[i]; i += 1
    if i:
        start = out[i][0]
        out = [o for o in out if o[0] >= start]
print(json.dumps({'k': 'head', 'session': sid, 'path': short(path), 'size': size, 'next': nxt, 'start': start, 'fresh': fresh, 'earlier': before >= 0, 'more': nxt < size}))
print('\n'.join(e for _, e in out))
"""#
        .replacingOccurrences(of: "INITIAL", with: String(initialTail))
        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
        .replacingOccurrences(of: "MAXREAD", with: String(maxRead))
}
