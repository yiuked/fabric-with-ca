#!/bin/bash

CHANNEL_NAME="zsjr"
APP_PATH=/home/vagrant/fabric
EXAMPLE="example_v"
ORDER="order_v"


CAFILE=/home/vagrant/fabric/crypto-config/ordererOrganizations/36sn.com/orderers/orderer.36sn.com/msp/tlscacerts/tlsca.36sn.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/home/vagrant/fabric/crypto-config/peerOrganizations/org1.36sn.com/users/Admin@org1.36sn.com/msp
export FABRIC_CFG_PATH=/home/vagrant/fabric/config
export GOPATH=/home/vagrant/go

function example() {
    set -x
    ${APP_PATH}/bin/peer chaincode install -n ${EXAMPLE} -v 0.0.1 -p github.com/hyperledger/fabric-demo/chaincode/chaincode_example02/go/ --tls --cafile=${CAFILE}
    ${APP_PATH}/bin/peer chaincode instantiate -o orderer.36sn.com:7050 -C zsjr -n ${EXAMPLE} -v 0.0.1 -c '{"Args":["init","a","100","b","200"]}' -P 'OR ('\''Org1MSP.member'\'')' --tls --cafile=${CAFILE}
    set +x
}

function order() {
    set -x
    ${APP_PATH}/bin/peer chaincode install -n ${ORDER} -v 0.0.1 -p  github.com/hyperledger/fabric-demo/chaincode/ocot/ --tls --cafile=${CAFILE}
    ${APP_PATH}/bin/peer chaincode instantiate -o orderer.36sn.com:7050 -C zsjr -n ${ORDER} -v 0.0.1 -c '{"Args":["init","a","100","b","200"]}' -P 'OR ('\''Org1MSP.member'\'')' --tls --cafile=${CAFILE}
    set +x
}
if [ -n "$2" ]; then
    EXAMPLE=${EXAMPLE}$2
    echo ${EXAMPLE}"\n"
    ORDER=${ORDER}$2
    echo ${ORDER}"\n"
fi

if [ -n "$1" ]; then
    if [ $1 == "example" ];then
        example
    elif [ $1 == "example" ];then
        order
    fi
fi


