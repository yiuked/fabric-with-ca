#!/bin/bash

. ./base.sh

CA_PID=0
TLS_PID=0
CA_DB='homestead:secret@tcp(localhost:3306)/fabric_ca?parseTime=true'
TLS_DB='homestead:secret@tcp(localhost:3306)/fabric_tls?parseTime=true'

function ClearProcess() {
    pidarr=$(ps x | grep 'fabric-ca-server' | awk '{print $1}')
    arr=($pidarr)
    len=${#arr[*]}
    if [ $len -gt 0 ];then
        indx=0
        while [ $indx -lt $len ]; do
            kill -9 ${arr[$indx]}
            echo "kill -9 "${arr[$indx]}
            indx=$[$indx+1]
        done
    else
        echo "该进程不存在"
    fi
}

function StartCA() {
    SERVER_DIR=${FABRIC_CLIENT_PATH}/../server
    rm -rf ${SERVER_DIR}/logs
    mkdir -p ${SERVER_DIR}/logs
    ${SERVER_DIR}/fabric-ca-server start -b admin:admin --db.datasource=${CA_DB} -p 7054 --cfg.affiliations.allowremove --cfg.identities.allowremove -H ${SERVER_DIR}/ca-home>${SERVER_DIR}/logs/ca-server.log &
    CA_PID=$!
    sleep 3
}

function StartTLS() {
    SERVER_DIR=${FABRIC_CLIENT_PATH}/../server
    rm -rf ${SERVER_DIR}/logs
    mkdir -p ${SERVER_DIR}/logs
    ${SERVER_DIR}/fabric-ca-server start -b admin:admin --db.datasource=${TLS_DB} -p 7055 --cfg.affiliations.allowremove --cfg.identities.allowremove -H ${SERVER_DIR}/tls-home>${SERVER_DIR}/logs/tls-server.log &
    TLS_PID=$!
    sleep 3
}

function AdminCA() {
    export FABRIC_CA_CLIENT_HOME=${FABRIC_CA_HOME}
    rm -rf ${FABRIC_CLIENT_PATH}/fabric-ca-client-config.yaml ${FABRIC_CLIENT_PATH}/users/ca-admin
    ${FABRIC_CLIENT_PATH}/fabric-ca-client enroll -u http://admin:admin@localhost:7054 -M ${FABRIC_CLIENT_PATH}/users/ca-admin/msp
}

function AdminTLS() {
    export FABRIC_CA_CLIENT_HOME=${FABRIC_TLS_HOME}
    rm -rf ${FABRIC_CLIENT_PATH}/fabric-ca-client-config.yaml ${FABRIC_CLIENT_PATH}/users/tls-admin
    ${FABRIC_CLIENT_PATH}/fabric-ca-client enroll -u http://admin:admin@localhost:7055 -M ${FABRIC_CLIENT_PATH}/users/tls-admin/msp
}

function StopCA() {
  if [ ${CA_PID} -gt 0 ];then
    kill -9 ${CA_PID}
  fi

}

function StopTLS() {
  if [ ${TLS_DB} -gt 0 ];then
    kill -9 ${TLS_DB}
  fi
}

# $1 user
# $2 password
# $3 type
# $4 affiliation
# $5 role
function RegisterCANode() {
    export FABRIC_CA_CLIENT_HOME=${FABRIC_CA_HOME}
    NodeDir=${APP_PATH}/crypto-config/$3Organizations/$4
    
    set -x
    rm -rf $NodeDir
    ${FABRIC_CLIENT_PATH}/fabric-ca-client identity remove $1
    ${FABRIC_CLIENT_PATH}/fabric-ca-client identity remove Admin@$4
    set +x
    
    # 1.register org
    mkdir -p ${NodeDir}/ca ${NodeDir}/msp ${NodeDir}/msp/admincerts ${NodeDir}/msp/cacerts ${NodeDir}/msp/tlscacerts ${NodeDir}/$3s ${NodeDir}/tlsca ${NodeDir}/users
    

    set -x
    ${FABRIC_CLIENT_PATH}/fabric-ca-client register --id.type $3 --id.name $1 --id.secret $2 --id.affiliation $4 --id.attrs '"hf.Registrar.Roles=$5,CLIENT,ADMIN","hf.Revoker=true"'
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to register ..."
        exit 1
    fi
    echo 
    
    set -x
    ${FABRIC_CLIENT_PATH}/fabric-ca-client enroll -u http://$1:$2@localhost:7054 -M ${NodeDir}/$3s/$1/msp
    set +x
    echo 
    
    # rename
    mv ${NodeDir}/$3s/$1/msp/cacerts/*.pem ${NodeDir}/$3s/$1/msp/cacerts/ca.$4-cert.pem

    
    # 1.2.create org msp and ca and tls
    cp ${NodeDir}/$3s/$1/msp/cacerts/*.pem ${NodeDir}/msp/cacerts
    cp ${NodeDir}/$3s/$1/msp/tlscacerts/*.pem ${NodeDir}/msp/tlscacerts
    cp ${NodeDir}/$3s/$1/msp/cacerts/*.pem ${NodeDir}/ca
    cp ${NodeDir}/$3s/$1/msp/tlscacerts/*.pem ${NodeDir}/tlsca



    # 1.3.register peer admin
    set -x
    ${FABRIC_CLIENT_PATH}/fabric-ca-client register --id.type $3 --id.name Admin@$4 --id.secret $2 --id.affiliation $4 --id.attrs '"hf.Registrar.Roles=ADMIN","hf.Revoker=true"'
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to register ..."
        exit 1
    fi
    echo 

    set -x
    ${FABRIC_CLIENT_PATH}/fabric-ca-client enroll -u http://$1:$2@localhost:7054 -M ${NodeDir}/users/Admin@$4/msp
    set +x
    echo 
    
    # rename
    mv ${NodeDir}/users/Admin@$4/msp/cacerts/*.pem ${NodeDir}/users/Admin@$4/msp/cacerts/ca.$4-cert.pem
    
    # 1.4.create orderer user
    mkdir ${NodeDir}/users/Admin@$4/msp/admincerts
    mkdir ${NodeDir}/$3s/$1/msp/admincerts
    cp ${NodeDir}/users/Admin@$4/msp/signcerts/*.pem ${NodeDir}/users/Admin@$4/msp/admincerts
    cp ${NodeDir}/users/Admin@$4/msp/admincerts/*.pem ${NodeDir}/msp/admincerts
    cp ${NodeDir}/users/Admin@$4/msp/admincerts/*.pem ${NodeDir}/$3s/$1/msp/admincerts
    
}

# $1 user
# $2 password
# $3 type
# $4 affiliation
# $5 role
function RegisterTLSNode() {
    export FABRIC_CA_CLIENT_HOME=${FABRIC_TLS_HOME}
    
    NodeDir=${APP_PATH}/crypto-config/$3Organizations/$4
    
    set -x
    ${FABRIC_CLIENT_PATH}/fabric-ca-client identity remove $1
    ${FABRIC_CLIENT_PATH}/fabric-ca-client identity remove Admin@$4
    set +x
    
    set -x
    ${FABRIC_CLIENT_PATH}/fabric-ca-client register --id.type $3 --id.name $1 --id.secret $2 --id.affiliation $4 --id.attrs '"hf.Registrar.Roles=$5,CLIENT,ADMIN","hf.Revoker=true"'
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to register ..."
        exit 1
    fi
    echo 
    
    set -x
    ${FABRIC_CLIENT_PATH}/fabric-ca-client enroll -u http://$1:$2@localhost:7055 -M ${NodeDir}/$3s/$1/tls
    set +x
    echo 
    
    # rename
    mv ${NodeDir}/$3s/$1/tls/cacerts/*.pem ${NodeDir}/$3s/$1/tls/cacerts/tlsca.$4-cert.pem
    mkdir -p ${NodeDir}/$3s/$1/msp/tlscacerts
    cp ${NodeDir}/$3s/$1/tls/cacerts/*.pem ${NodeDir}/$3s/$1/msp/tlscacerts/tlsca.$4-cert.pem

    # 1.2.create peer tls
    mkdir -p ${NodeDir}/$3s/$1/tls
    mv ${NodeDir}/$3s/$1/tls/cacerts/*.pem ${NodeDir}/$3s/$1/tls/ca.crt
    mv ${NodeDir}/$3s/$1/tls/keystore/*_sk ${NodeDir}/$3s/$1/tls/server.key
    mv ${NodeDir}/$3s/$1/tls/signcerts/*.pem ${NodeDir}/$3s/$1/tls/server.crt
    rm -rf ${NodeDir}/$3s/$1/tls/cacerts
    rm -rf ${NodeDir}/$3s/$1/tls/keystore
    rm -rf ${NodeDir}/$3s/$1/tls/signcerts
    rm -rf ${NodeDir}/$3s/$1/tls/user
    
    # 1.3.register peer admin
    set -x
    ${FABRIC_CLIENT_PATH}/fabric-ca-client register --id.type $3 --id.name Admin@$4 --id.secret $2 --id.affiliation $4 --id.attrs '"hf.Registrar.Roles=ADMIN","hf.Revoker=true"'
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to register ..."
        exit 1
    fi
    echo 
    
    set -x
    ${FABRIC_CLIENT_PATH}/fabric-ca-client enroll -u http://$1:$2@localhost:7055 -M ${NodeDir}/users/Admin@$4/tls
    set +x
    echo 
    
    # rename
    mv ${NodeDir}/users/Admin@$4/tls/cacerts/*.pem ${NodeDir}/users/Admin@$4/tls/cacerts/tlsca.$4-cert.pem
    mkdir -p ${NodeDir}/users/Admin@$4/msp/tlscacerts
    cp ${NodeDir}/users/Admin@$4/tls/cacerts/*.pem ${NodeDir}/users/Admin@$4/msp/tlscacerts/tlsca.$4-cert.pem
    
    # 1.4.create orderer user tls
    cp ${NodeDir}/users/Admin@$4/tls/cacerts/*.pem ${NodeDir}/users/Admin@$4/tls/ca.crt
    cp ${NodeDir}/users/Admin@$4/tls/keystore/*_sk ${NodeDir}/users/Admin@$4/tls/server.key
    cp ${NodeDir}/users/Admin@$4/tls/signcerts/*.pem ${NodeDir}/users/Admin@$4/tls/server.crt
    rm -rf ${NodeDir}/users/Admin@$4/tls/cacerts
    rm -rf ${NodeDir}/users/Admin@$4/tls/keystore
    rm -rf ${NodeDir}/users/Admin@$4/tls/signcerts
    rm -rf ${NodeDir}/users/Admin@$4/tls/user
}

ClearProcess
StartCA
StartTLS
AdminCA
AdminTLS
RegisterCANode orderer.36sn.com abc123 orderer 36sn.com ORDERER
RegisterTLSNode orderer.36sn.com abc123 orderer 36sn.com ORDERER
RegisterCANode peer0.org1.36sn.com abc123 peer org1.36sn.com PEER
RegisterTLSNode peer0.org1.36sn.com abc123 peer org1.36sn.com PEER
StopCA
StopTLS