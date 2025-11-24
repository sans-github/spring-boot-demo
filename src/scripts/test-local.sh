HOST=localhost
# HOST=52.53.228.183
URL_BASE="http://"$HOST":8080/author"

function testGet() {
  _testSetAPIPath
  if [ "$#" -eq 1 ]; then
    local AUTHOR_ID=$1
  else
    local AUTHOR_ID=1
  fi

  local FULL_URL="$URL_BASE?author_id=$AUTHOR_ID"

  echo "$FULL_URL"
  echo "$FULL_URL" | pbcopy
  curl -sk $FULL_URL
}

function testPost() {
  _testSetAPIPath
  if [ "$#" -ne 1 ]; then
    echo "Missing param"
    echo "$funcname author_id"
    echo "Exiting ..."
    return 
  fi

  local AUTHOR_ID=$1

  POST_BODY=$(cat << EOF
  {
    "author_id": $AUTHOR_ID,
    "name": "Billy Baker"
  }
EOF
)
  echo "$POST_BODY"
  _testApiPost "$URL_BASE" "$POST_BODY"
}

function testSshEC2Notes() {
  _testApiLoadOnClipboard "ssh -i ~/.ssh/tf_ec2_key.pem ec2-user@"$HOST
  
  _testApiLoadOnClipboard "cat /var/log/cloud-init-output.log"

  _testApiLoadOnClipboard "cat /tmp/logs/access*"
}

function _testApiLoadOnClipboard() {
  echo "$1"
  echo "$1" | pbcopy
  sleep 1
}

function _testApiPost() {
  local URL_BASE=$1
  local POST_BODY="$2"
  
  local RESPONSE=$(curl -sk "$URL_BASE" -X POST -H "Content-Type: application/json" -d "$POST_BODY")

  echo "$RESPONSE" | jq empty
  exit_status=$?

  echo "\n=POST $URL_BASE=\n";
  if [ $exit_status -eq 0 ]; then
    echo "$RESPONSE" | python3 -m json.tool;
  else 
    echo "***Operation failed***"
    curl -v "$URL"
  fi

  echo "\n==\n";
}

function _testSetAPIPath() {
  local TF_URL=$(terraform output -raw api_invoke_base_url 2>/dev/null)

  if [[ -n "$TF_URL" && "$TF_URL" != *"No outputs found"* ]]; then
    URL_BASE="$TF_URL"
  fi

  echo "URL_BASE: $URL_BASE"
}

