#!/bin/bash

APP_PATH=/home/vagrant/fabric

docker-compose down
../shell/generate.sh
docker-compose up -d 2>&1>>${APP_PATH}/logs/orderer.log

