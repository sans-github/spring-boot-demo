#!/bin/bash

input=$(cat)
echo "$input" | grep -q '\.java' || exit 0

PORT=9091
HTML=".claude/verification-results.html"
TIMESTAMP=$(TZ="America/Los_Angeles" date "+%Y-%m-%d %H:%M:%S %Z")

lsof -ti tcp:$PORT | xargs kill -9 2>/dev/null; true

# Build
mvn clean package -DskipTests -q
if [ $? -ne 0 ]; then
  printf 'build-failed' > /tmp/smoke-post-verdict.txt
  cat > "$HTML" <<EOF
<!DOCTYPE html><html><body><h2>Verification Results</h2>
<p><strong>$TIMESTAMP</strong></p>
<p style="color:red;font-weight:bold">BUILD FAILED</p>
</body></html>
EOF
  exit 1
fi

JAR=$(ls target/*.jar 2>/dev/null | head -1)
java -jar "$JAR" --server.port=$PORT > /tmp/app-post.log 2>&1 &
APP_PID=$!
cleanup() { kill $APP_PID 2>/dev/null; wait $APP_PID 2>/dev/null; }
trap cleanup EXIT

sleep 5
for i in $(seq 1 20); do
  curl -s --max-time 2 "http://localhost:$PORT/author?author_id=0" > /dev/null 2>&1 && break
  sleep 1
done

# Smoke
TMPFILE=$(mktemp)
SMOKE_POST_STATUS=$(curl -s --max-time 10 -o "$TMPFILE" -w "%{http_code}" \
  -X POST "http://localhost:$PORT/author" -H "Content-Type: application/json" \
  -d '{"author_id": 9999, "name": "Hook Test"}')
SMOKE_POST_RESP=$(cat "$TMPFILE"); rm "$TMPFILE"

sleep 1

TMPFILE=$(mktemp)
SMOKE_GET_STATUS=$(curl -s --max-time 10 -o "$TMPFILE" -w "%{http_code}" \
  "http://localhost:$PORT/author?author_id=9999")
SMOKE_GET_RESP=$(cat "$TMPFILE"); rm "$TMPFILE"

printf '%s' "$SMOKE_POST_STATUS" > /tmp/smoke-post-post-status.txt
printf '%s' "$SMOKE_POST_RESP"   > /tmp/smoke-post-post-resp.txt
printf '%s' "$SMOKE_GET_STATUS"  > /tmp/smoke-post-get-status.txt
printf '%s' "$SMOKE_GET_RESP"    > /tmp/smoke-post-get-resp.txt
if echo "$SMOKE_GET_RESP" | grep -q "Hook Test"; then
  printf 'ok'   > /tmp/smoke-post-verdict.txt
else
  printf 'fail' > /tmp/smoke-post-verdict.txt
fi

# Perf
echo ">>> POST VERIFY: running 1000 POST requests (50 concurrent)..." > /dev/tty
T0=$(python3 -c "import time; print(time.time())")
seq 1 1000 | xargs -P 50 -I {} bash -c \
  'curl -s -o /dev/null -w "%{http_code} %{time_total}\n" \
    -X POST -H "Content-Type: application/json" \
    -d "{\"author_id\":{}, \"name\":\"Author {}\"}" \
    http://localhost:'"$PORT"'/author' > /tmp/perf-post.txt
T1=$(python3 -c "import time; print(time.time())")
POST_ELAPSED=$(python3 -c "print(round($T1-$T0,3))")
printf '%s' "$POST_ELAPSED" > /tmp/perf-post-elapsed.txt

PRE_ELAPSED=$(cat /tmp/perf-pre-elapsed.txt 2>/dev/null || echo "1")

# Generate HTML
PERF_METRICS=$(python3 - /tmp/perf-pre.txt "$PRE_ELAPSED" /tmp/perf-post.txt "$POST_ELAPSED" <<'PYEOF'
import sys

def parse(path, elapsed):
    elapsed = float(elapsed)
    try:
        lines = open(path).readlines()
    except:
        return None
    codes, times = [], []
    for l in lines:
        p = l.strip().split()
        if len(p) >= 2:
            codes.append(p[0])
            try: times.append(float(p[1]) * 1000)
            except: pass
    n = len(times)
    if n == 0:
        return None
    ts = sorted(times)
    ok = sum(1 for c in codes if c.startswith('2'))
    e4 = sum(1 for c in codes if c.startswith('4'))
    e5 = sum(1 for c in codes if c.startswith('5'))
    return dict(
        n=n, ok=ok, e4=e4, e5=e5,
        avg=sum(times)/n, mn=ts[0], mx=ts[-1],
        p50=ts[int(n*0.50)], p75=ts[int(n*0.75)],
        p95=ts[int(n*0.95)], p99=ts[int(n*0.99)],
        rps=round(n/elapsed, 1), elapsed=elapsed
    )

def fmt(v, d=2): return f"{v:.{d}f}" if v is not None else "n/a"

def delta(b, a, lib=True):
    if b is None or a is None or b == 0:
        return '<span style="color:#888">&mdash;</span>'
    pct = (a - b) / b * 100
    if abs(pct) < 5:
        return f'<span style="color:#888">{pct:+.1f}%</span>'
    improved = (pct < 0) if lib else (pct > 0)
    color = "green" if improved else "#e05252"
    arrow = "&#9650;" if pct > 0 else "&#9660;"
    return f'<span style="color:{color};font-weight:bold">{arrow} {abs(pct):.1f}%</span>'

def row(label, bv, av, lib=True, d=2):
    return f"<tr><td>{label}</td><td>{fmt(bv,d) if bv is not None else 'n/a'}</td><td>{fmt(av,d) if av is not None else 'n/a'}</td><td>{delta(bv,av,lib)}</td></tr>"

def sh(label):
    return f'<tr class="sh"><td colspan="4">{label}</td></tr>'

def sc(m, key):
    if m:
        v = m.get(key, 0); t = m.get('n', 1)
        return f"{v} ({v/t*100:.1f}%)"
    return "n/a"

pre  = parse(sys.argv[1], sys.argv[2])
post = parse(sys.argv[3], sys.argv[4])
p = pre or {}; q = post or {}

rows = [
    sh("Throughput"),
    row("Total time (s)", p.get("elapsed"), q.get("elapsed"), lib=True,  d=3),
    row("Req/sec",        p.get("rps"),     q.get("rps"),     lib=False, d=1),
    sh("Latency (ms)"),
    row("Avg", p.get("avg"), q.get("avg")),
    row("Min", p.get("mn"),  q.get("mn")),
    row("Max", p.get("mx"),  q.get("mx")),
    row("p50", p.get("p50"), q.get("p50")),
    row("p75", p.get("p75"), q.get("p75")),
    row("p95", p.get("p95"), q.get("p95")),
    row("p99", p.get("p99"), q.get("p99")),
    sh("HTTP Status"),
    f"<tr><td>2xx</td><td>{sc(pre,'ok')}</td><td>{sc(post,'ok')}</td><td>&mdash;</td></tr>",
    f"<tr><td>4xx</td><td>{sc(pre,'e4')}</td><td>{sc(post,'e4')}</td><td>&mdash;</td></tr>",
    f"<tr><td>5xx</td><td>{sc(pre,'e5')}</td><td>{sc(post,'e5')}</td><td>&mdash;</td></tr>",
]
print("\n".join(rows))
PYEOF
)

verdict_html() {
  case "$1" in
    ok)           echo "<span class='ok'>OK</span>" ;;
    build-failed) echo "<span class='fail'>BUILD FAILED</span>" ;;
    *)            echo "<span class='fail'>FAIL</span>" ;;
  esac
}

PRE_V=$(cat /tmp/smoke-pre-verdict.txt 2>/dev/null || echo "n/a")
POST_V=$(cat /tmp/smoke-post-verdict.txt 2>/dev/null || echo "n/a")
PRE_POST_S=$(cat /tmp/smoke-pre-post-status.txt 2>/dev/null || echo "n/a")
PRE_POST_R=$(cat /tmp/smoke-pre-post-resp.txt   2>/dev/null || echo "n/a")
PRE_GET_S=$(cat /tmp/smoke-pre-get-status.txt   2>/dev/null || echo "n/a")
PRE_GET_R=$(cat /tmp/smoke-pre-get-resp.txt     2>/dev/null || echo "n/a")
POST_POST_S=$(cat /tmp/smoke-post-post-status.txt 2>/dev/null || echo "n/a")
POST_POST_R=$(cat /tmp/smoke-post-post-resp.txt   2>/dev/null || echo "n/a")
POST_GET_S=$(cat /tmp/smoke-post-get-status.txt   2>/dev/null || echo "n/a")
POST_GET_R=$(cat /tmp/smoke-post-get-resp.txt     2>/dev/null || echo "n/a")

PRE_V_HTML=$(verdict_html "$PRE_V")
POST_V_HTML=$(verdict_html "$POST_V")

cat > "$HTML" <<EOF
<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<title>Verification Results</title>
<style>
  body { font-family: monospace; padding: 20px; background: #fff; color: #222; }
  h2 { margin-bottom: 4px; }
  h3 { color: #333; margin-top: 28px; margin-bottom: 8px; }
  p  { color: #666; margin-top: 4px; }
  table { border-collapse: collapse; margin-top: 12px; }
  th, td { border: 1px solid #ccc; padding: 7px 12px; vertical-align: top; text-align: left; }
  th { background: #f0f0f0; }
  pre { margin: 0; white-space: pre-wrap; word-break: break-all; }
  .ok   { color: green; font-weight: bold; }
  .fail { color: #e05252; font-weight: bold; }
  .perf td:not(:first-child) { text-align: right; }
  tr.sh td { background: #f8f8f8; color: #888; font-size: 0.82em; text-transform: uppercase; letter-spacing: .05em; border-color: #ddd; }
</style>
</head>
<body>
<h2>Verification Results</h2>
<p><strong>$TIMESTAMP</strong></p>

<h3>Smoke Test</h3>
<table>
<tr>
  <th>#</th><th>Method</th><th>URL</th><th>Body</th>
  <th>Before Status</th><th>After Status</th>
  <th>Before Response</th><th>After Response</th>
  <th>Verdict</th>
</tr>
<tr>
  <td>1</td><td>POST</td><td>/author</td>
  <td><pre>{"author_id": 9999, "name": "Hook Test"}</pre></td>
  <td>$PRE_POST_S</td><td>$POST_POST_S</td>
  <td><pre>$PRE_POST_R</pre></td><td><pre>$POST_POST_R</pre></td>
  <td>$PRE_V_HTML &rarr; $POST_V_HTML</td>
</tr>
<tr>
  <td>2</td><td>GET</td><td>/author?author_id=9999</td>
  <td></td>
  <td>$PRE_GET_S</td><td>$POST_GET_S</td>
  <td><pre>$PRE_GET_R</pre></td><td><pre>$POST_GET_R</pre></td>
  <td></td>
</tr>
</table>

<h3>Performance &middot; POST /author &middot; 1000 req &middot; 50 concurrent</h3>
<table class="perf">
<tr><th>Metric</th><th>Before</th><th>After</th><th>&Delta;</th></tr>
$PERF_METRICS
</table>
</body></html>
EOF

echo ">>> verification-results.html written ($TIMESTAMP)"
