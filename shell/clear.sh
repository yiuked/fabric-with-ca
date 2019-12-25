#!/bin/bash

source ./base.sh

set -
ps aux|grep 'bin/peer'|awk '{print $2}'|xargs kill -9
ps aux|grep 'bin/orderer'|awk '{print $2}'|xargs kill -9
set +x

echo "===================== Kill orderer and peer ===================== "

set -x
# rm -rf ${APP_PATH}/crypto-config/*
rm -rf ${APP_PATH}/channel-artifacts/*
rm -rf /var/hyperledger/production/*
rm -rf ${APP_PATH}/production/*
rm -rf ${APP_PATH}/logs/*
set +x
