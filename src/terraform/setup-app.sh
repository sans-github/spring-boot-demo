#!/bin/bash
set -e

# # Delete the log file to avoid confusion
# sudo rm -f /var/log/cloud-init-output.log

# --> Set to pacfic timezone
echo "Setting to PST"
sudo timedatectl set-timezone America/Los_Angeles

# Update system packages
sudo dnf update -y

# Install dependencies
echo "Installing gittt"
sudo dnf install -y git 

echo "Installing javaaa"
sudo dnf install -y java-21-amazon-corretto-devel 

echo "Installing mavennn"
sudo dnf install -y maven

# Set path for JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto
export PATH=$JAVA_HOME/bin:$PATH

# Set path for M2_HOME
export M2_HOME=/usr/share/maven
export PATH=$M2_HOME/bin:$PATH

# Clone app
APP_DIR="/home/ec2-user/my-api"
if [ ! -d "$APP_DIR" ]; then
  git clone https://github.com/sans-github/spring-boot-demo.git "$APP_DIR"
fi
cd "$APP_DIR"

# Install app dependencies
mvn clean install

# Run the app
# java -jar target/spring-boot-demo-0.0.1-SNAPSHOT.jar
nohup java -jar target/spring-boot-demo-0.0.1-SNAPSHOT.jar > /home/ec2-user/app.log 2>&1 &

sleep 10
curl -f http://localhost:8080 || echo "App failed to start"