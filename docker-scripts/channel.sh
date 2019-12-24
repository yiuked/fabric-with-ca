#!/bin/bash

CHANNEL_NAME="zsjr"
APP_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer
BLOCK_PATH=${APP_PATH}/channel-artifacts/${CHANNEL_NAME}.block
CHANNEL_PATH=${APP_PATH}/channel-artifacts/channel.tx
ANCHORS_PATH=${APP_PATH}/channel-artifacts/anchors.tx
ORDERER_ADDR=orderer.36sn.com:7050
CAFILE=${APP_PATH}/crypto/ordererOrganizations/36sn.com/orderers/orderer.36sn.com/msp/tlscacerts/tlsca.36sn.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=${APP_PATH}/crypto/peerOrganizations/org1.36sn.com/users/Admin@org1.36sn.com/msp

env|grep PEER
echo "=======================Start ...========================"
set -x
peer channel create -o ${ORDERER_ADDR} -c ${CHANNEL_NAME} -f ${CHANNEL_PATH}  --outputBlock=${BLOCK_PATH} --tls --cafile=${CAFILE}
res=$?
set +x
if [ $res -ne 0 ]; then
    echo "Failed to create channel..."
    exit 1
fi
set -x
peer channel join -b ${BLOCK_PATH} --tls --cafile=${CAFILE}
res=$?
set +x
if [ $res -ne 0 ]; then
    echo "Failed to join channel..."
    exit 1
fi
set -x
peer channel update -o ${ORDERER_ADDR} -c ${CHANNEL_NAME} -f ${ANCHORS_PATH} --tls --cafile=${CAFILE}
res=$?
set +x
if [ $res -ne 0 ]; then
    echo "Failed to update channel..."
    exit 1
fi

