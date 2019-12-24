#!/bin/bash

CHANNEL_NAME="zsjr"
APP_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer

export CORE_PEER_MSPCONFIGPATH=${APP_PATH}/crypto-config/peerOrganizations/org1.36sn.com/users/Admin@org1.36sn.com/msp

peer chaincode install -n example -v 0.0.1 -p github.com/hyperledger/fabric-demo/chaincode/chaincode_example02/go/
peer chaincode instantiate -o orderer.36sn.com:7050 -C zsjr -n example -v 0.0.1 -c '{"Args":["init","a","100","b","200"]}' -P 'OR ('\''Org1MSP.member'\'')'

