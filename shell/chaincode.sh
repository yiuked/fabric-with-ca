#!/bin/bash

CHANNEL_NAME="zsjr"
APP_PATH=/home/vagrant/fabric
EXAMPLE="example_v"
ORDER="order_v"

CAFILE=/home/vagrant/fabric/crypto-config/ordererOrganizations/36sn.com/orderers/orderer.36sn.com/msp/tlscacerts/tlsca.36sn.com-cert.pem

set -x
cd ${APP_PATH}
export CORE_PEER_MSPCONFIGPATH=/home/vagrant/fabric/crypto-config/peerOrganizations/org1.36sn.com/users/Admin@org1.36sn.com/msp
export FABRIC_CFG_PATH=/home/vagrant/fabric/config
export GOPATH=/home/vagrant/go
set +x

function printHelp() {
  echo "Usage: "
  echo "  chaicode.sh <mode> [chaincode] [version]"
  echo "    <mode> - one of 'install', 'query'"
  echo "      - 'install' - install and instantiate chaincode"
  echo "      - 'query' - query installed and instantiated chaincode list"
  echo "    [chaincode] - current support 'example' and 'order'"
  echo "    [version] - a number"
}

function installExample() {
    set -x
    ${APP_PATH}/bin/peer chaincode install -n ${EXAMPLE} -v 0.0.1 -p github.com/hyperledger/fabric-demo/chaincode/chaincode_example02/go/ --tls --cafile=${CAFILE}
    if [ $? -eq 0 ];then 
    ${APP_PATH}/bin/peer chaincode instantiate -o orderer.36sn.com:7050 -C ${CHANNEL_NAME} -n ${EXAMPLE} -v 0.0.1 -c '{"Args":["init","a","100","b","200"]}' -P 'OR ('\''Org1MSP.member'\'')' --tls --cafile=${CAFILE}
    fi
    set +x
    echo
}

function installOrder() {
    set -x
    ${APP_PATH}/bin/peer chaincode install -n ${ORDER} -v 0.0.1 -p  github.com/hyperledger/fabric-demo/chaincode/ocot/ --tls --cafile=${CAFILE}
    if [ $? -eq 0 ];then 
    ${APP_PATH}/bin/peer chaincode instantiate -o orderer.36sn.com:7050 -C ${CHANNEL_NAME} -n ${ORDER} -v 0.0.1 -c '{"Args":["init","a","100","b","200"]}' -P 'OR ('\''Org1MSP.member'\'')' --tls --cafile=${CAFILE}
    fi
    set +x
    echo
}

function queryInstall() {
    set -x
    ${APP_PATH}/bin/peer chaincode list --installed
    set +x
    echo
}

function queryInstantiate() {
    set -x
    ${APP_PATH}/bin/peer chaincode -C ${CHANNEL_NAME} list --instantiated
    set +x
    echo
}

if [ -n "$3" ]; then
    EXAMPLE=${EXAMPLE}$3
    ORDER=${ORDER}$3
fi

if [ -n "$1" ]; then
    if [ $1 == "install" ];then
        if [ -n "$2" ]; then
            if [ $2 == "example" ];then
                installExample
            elif [ $2 == "order" ];then
                installOrder
            else
                echo "Not fund chaincode $2"
            fi
         else
            installExample
            installOrder
         fi
     elif [ $1 == "query" ];then
        queryInstall
        queryInstantiate
     fi
else
    printHelp
fi


