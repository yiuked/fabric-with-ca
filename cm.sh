#!/bin/bash

COMPOSE_FILE=docker-compose-ca.yaml
MODE=$1

export BYFN_CA1_PRIVATE_KEY=$(cd crypto-config/peerOrganizations/org1.example.com/ca && ls *_sk)
export BYFN_CA2_PRIVATE_KEY=$(cd crypto-config/peerOrganizations/org2.example.com/ca && ls *_sk)

function Start() {
    docker-compose -f $COMPOSE_FILE up -d 2>&1
    docker ps -a
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start network"
        exit 1
    fi
}

function Down() {
    docker-compose -f $COMPOSE_FILE down --volumes --remove-orphans
  
    rm -rf crypto-config
}

if [ "$MODE" == "down" ];then
    Down
fi

if [ "$MODE" == "start" ];then
    Start
fi