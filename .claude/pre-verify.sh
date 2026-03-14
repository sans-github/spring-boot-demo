#!/bin/bash

input=$(cat)
echo "$input" | grep -q '\.java' || exit 0

PORT=9091
echo ">>> PRE VERIFY: starting app on port $PORT..." > /dev/tty

lsof -ti tcp:$PORT | xargs kill -9 2>/dev/null; true

JAR=$(ls target/*.jar 2>/dev/null | head -1)
if [ -z "$JAR" ]; then
  echo ">>> PRE VERIFY: no jar found, skipping" > /dev/tty
  exit 0
fi

java -jar "$JAR" --server.port=$PORT > /tmp/app-pre.log 2>&1 &
APP_PID=$!
cleanup() { kill $APP_PID 2>/dev/null; wait $APP_PID 2>/dev/null; }
trap cleanup EXIT

sleep 3
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

printf '%s' "$SMOKE_POST_STATUS" > /tmp/smoke-pre-post-status.txt
printf '%s' "$SMOKE_POST_RESP"   > /tmp/smoke-pre-post-resp.txt
printf '%s' "$SMOKE_GET_STATUS"  > /tmp/smoke-pre-get-status.txt
printf '%s' "$SMOKE_GET_RESP"    > /tmp/smoke-pre-get-resp.txt
if echo "$SMOKE_GET_RESP" | grep -q "Hook Test"; then
  printf 'ok'   > /tmp/smoke-pre-verdict.txt
else
  printf 'fail' > /tmp/smoke-pre-verdict.txt
fi

# Perf
echo ">>> PRE VERIFY: running 1000 POST requests (50 concurrent)..." > /dev/tty
T0=$(python3 -c "import time; print(time.time())")
seq 1 1000 | xargs -P 50 -I {} bash -c \
  'curl -s -o /dev/null -w "%{http_code} %{time_total}\n" \
    -X POST -H "Content-Type: application/json" \
    -d "{\"author_id\":{}, \"name\":\"Author {}\"}" \
    http://localhost:'"$PORT"'/author' > /tmp/perf-pre.txt
T1=$(python3 -c "import time; print(time.time())")
python3 -c "print(round($T1-$T0,3))" > /tmp/perf-pre-elapsed.txt

echo ">>> PRE VERIFY: done (smoke + perf baseline captured)" > /dev/tty
