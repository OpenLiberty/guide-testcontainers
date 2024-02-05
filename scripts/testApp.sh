#!/bin/bash
set -euxo pipefail

# TEST 1:  Running the test by using Testcontainers
mvn -ntp -q clean package

docker pull -q icr.io/appcafe/open-liberty:kernel-slim-java11-openj9-ubi

mvn -ntp verify

# TEST 2: Running the test by local runtime
cd ../postgres

docker build -t postgres-sample .
docker run --name postgres-container -p 5432:5432 -d postgres-sample
docker logs postgres-container

cd ../finish

mvn -ntp -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    liberty:create liberty:install-feature liberty:deploy
mvn -ntp liberty:start
mvn -ntp -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    failsafe:integration-test liberty:stop
mvn -ntp failsafe:verify

docker stop postgres-container
docker rm postgres-container
