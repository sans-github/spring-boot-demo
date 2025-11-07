APP_NAME=aws_instance.webapp
KEY_NAME=tf_ec2_key
TEST_LOC=8080/test

function tfTest {
  local PUBLIC_IP=$(terraform state show $APP_NAME | grep "public_ip" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

  _tfDisplayDetails "$PUBLIC_IP"
  
  local TEST_URL="http://"$PUBLIC_IP":"$TEST_LOC
  _tfRunCurlUntilSuccess $TEST_URL
}

function tfApplyAndTest {
  local PUBLIC_IP=$(terraform apply; terraform state show $APP_NAME | grep "public_ip" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

  _tfDisplayDetails "$PUBLIC_IP"

  local TEST_URL="http://"$PUBLIC_IP":"$TEST_LOC
  _tfRunCurlUntilSuccess $TEST_URL
}

function _tfDisplayDetails() {
  local PUBLIC_IP="$1"

  local TEST_URL="http://"$PUBLIC_IP":"$TEST_LOC

  printf "\n================"
  echo "App name: $APP_NAME"
  echo "Key: $KEY_NAME"
  echo "Test URL: $TEST_URL"
  printf "================"

  printf "\nLoading clipboard\n\n"
  
  echo "$TEST_URL" | pbcopy
  echo "$TEST_URL"
  sleep 1s

  local SSH_STRING=("ssh -i ~/.ssh/"$KEY_NAME".pem ec2-user@"$PUBLIC_IP)
  echo "$SSH_STRING" | pbcopy
  echo "$SSH_STRING"
}

function _tfRunCurlUntilSuccess() {
  PUBLIC_URL="$1"
  
  printf "\n\nTesting ..\n"
  while true; do
  code=$(curl -s -o /dev/null -w "%{http_code}" $PUBLIC_URL)
  echo "Response code: $code"
  if [ "$code" -eq 200 ]; then
    echo "Server is ready. Full response below:"
    curl -s $PUBLIC_URL
    break
  fi
  sleep 1
  done
}