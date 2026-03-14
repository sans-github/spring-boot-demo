#!/bin/bash

input=$(cat)
echo "$input" | grep -q '\.java' || exit 0

PORT=9091
HTML=".claude/post-verify.html"
TIMESTAMP=$(TZ="America/Los_Angeles" date "+%Y-%m-%d %H:%M:%S %Z")

write_html() {
  cat > "$HTML" <<EOF
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Post Verify Results</title>
<style>
  body { font-family: monospace; padding: 20px; }
  h2 { margin-bottom: 4px; }
  table { border-collapse: collapse; width: 100%; margin-top: 16px; }
  th, td { border: 1px solid #ccc; padding: 8px 12px; vertical-align: top; text-align: left; }
  th { background: #f0f0f0; }
  .ok { color: green; font-weight: bold; }
  .fail { color: red; font-weight: bold; }
  pre { margin: 0; white-space: pre-wrap; word-break: break-all; }
</style>
</head>
<body>
<h2>post-verify results</h2>
<p><strong>$TIMESTAMP</strong></p>
<table>
<tr>
  <th>#</th><th>Method</th><th>URL</th><th>Request Body</th><th>Status</th><th>Response Body</th>
</tr>
$1
</table>
</body>
</html>
EOF
}

# Kill any leftover process on port
lsof -ti tcp:$PORT | xargs kill -9 2>/dev/null; true

# Build
mvn clean package -DskipTests -q
if [ $? -ne 0 ]; then
  write_html "<tr><td colspan='6' class='fail'>BUILD FAILED</td></tr>"
  exit 1
fi

JAR=$(ls target/*.jar 2>/dev/null | head -1)
java -jar "$JAR" --server.port=$PORT > /tmp/app-$PORT.log 2>&1 &
APP_PID=$!
cleanup() { kill $APP_PID 2>/dev/null; wait $APP_PID 2>/dev/null; }
trap cleanup EXIT

sleep 5
for i in $(seq 1 20); do
  curl -s --max-time 2 "http://localhost:$PORT/author?author_id=0" > /dev/null 2>&1 && break
  sleep 1
done

# POST
POST_URL="http://localhost:$PORT/author"
POST_BODY='{"author_id": 9999, "name": "Hook Test"}'
TMPFILE=$(mktemp)
POST_STATUS=$(curl -s --max-time 10 -o "$TMPFILE" -w "%{http_code}" \
  -X POST "$POST_URL" -H "Content-Type: application/json" -d "$POST_BODY")
POST_RESP=$(cat "$TMPFILE"); rm "$TMPFILE"

sleep 2

# GET
GET_URL="http://localhost:$PORT/author?author_id=9999"
TMPFILE=$(mktemp)
GET_STATUS=$(curl -s --max-time 10 -o "$TMPFILE" -w "%{http_code}" "$GET_URL")
GET_RESP=$(cat "$TMPFILE"); rm "$TMPFILE"

echo "$GET_RESP" | grep -q "Hook Test" && VERDICT="<span class='ok'>VERIFIED OK</span>" || VERDICT="<span class='fail'>VERIFICATION FAILED</span>"

ROWS="
<tr>
  <td>1</td><td>POST</td><td>$POST_URL</td>
  <td><pre>$POST_BODY</pre></td>
  <td>$POST_STATUS</td>
  <td><pre>$POST_RESP</pre></td>
</tr>
<tr>
  <td>2</td><td>GET</td><td>$GET_URL</td>
  <td></td>
  <td>$GET_STATUS</td>
  <td><pre>$GET_RESP</pre></td>
</tr>
<tr>
  <td colspan='6'>$VERDICT</td>
</tr>"

write_html "$ROWS"
echo ">>> post-verify.html written ($TIMESTAMP)"
