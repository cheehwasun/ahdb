#!/usr/bin/env bash
pwd

  # Install GraalVM with SDKMAN
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk install java 20.2.0.r11-grl

  # Check if GraalVM was installed successfully
  java -version

#  # Install Maven, that uses GraalVM for later builds
#  sdk install maven
#
#  # Show Maven using GraalVM JDK
#  mvn --version
#
#  # Install GraalVM Native Image
#  gu install native-image
#
#  # Check if Native Image was installed properly
#  native-image --version

echo '> env keys'

echo "$SERVER_HOST"

echo '> package'
./mvnw -version
#mvn package -Pnative

echo '> start'
touch rq
cat "mama" > rq
scp -P4422 rq root@"$SERVER_HOST":~/ahdb/server
