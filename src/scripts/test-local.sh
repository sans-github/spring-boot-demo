URL_BASE="http://localhost:8080/author"

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

  if [[ -n "$TF_URL" ]]; then
    URL_BASE="$TF_URL"
    echo "Terraform API URL set: $URL_BASE"
  fi
  echo "URL_BASE: $URL_BASE"
}