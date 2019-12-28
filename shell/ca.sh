#!/bin/bash

. ./base.sh

CA_PID=0

function Start(){
	SERVER_DIR=${FABRIC_CA_CLIENT_HOME}/../server
	rm -rf ${SERVER_DIR}/logs
	mkdir -p ${SERVER_DIR}/logs
	${SERVER_DIR}/fabric-ca-server start -b admin:admin --cfg.affiliations.allowremove --cfg.identities.allowremove -H ${SERVER_DIR}/ca-files>${SERVER_DIR}/logs/server.log &
	CA_PID=$!
}

function Admin(){
    rm -rf ${FABRIC_CA_CLIENT_HOME}/fabric-ca-client-config.yaml ${FABRIC_CA_CLIENT_HOME}/users/admin
    ${FABRIC_CA_CLIENT_HOME}/fabric-ca-client enroll -u http://admin:admin@localhost:7054 -M ${FABRIC_CA_CLIENT_HOME}/users/admin/msp
}

function Stop() {
  if [ ${CA_PID} -gt 0 ];then
    kill -9 ${CA_PID}
  fi
}


# $1 user
# $2 password
# $3 type
# $4 affiliation
# $5 role
function RegisterNode(){
    NodeDir=/home/vagrant/fabric-with-ca/crypto-config/$3Organizations/$4
    
    set -x
    rm -rf $NodeDir
    ${FABRIC_CA_CLIENT_HOME}/fabric-ca-client identity remove $1
    ${FABRIC_CA_CLIENT_HOME}/fabric-ca-client identity remove Admin@$4
    set +x
    
    # 1.register org
    mkdir -p ${NodeDir}/ca ${NodeDir}/msp ${NodeDir}/msp/admincerts ${NodeDir}/msp/cacerts ${NodeDir}/msp/tlscacerts ${NodeDir}/$3s ${NodeDir}/tlsca ${NodeDir}/users
    

    set -x
    ${FABRIC_CA_CLIENT_HOME}/fabric-ca-client register --id.type $3 --id.name $1 --id.secret $2 --id.affiliation $4 --id.attrs '"hf.Registrar.Roles=$5,CLIENT,ADMIN","hf.Revoker=true"'
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to register ..."
        exit 1
    fi
    echo 
    
    set -x
    ${FABRIC_CA_CLIENT_HOME}/fabric-ca-client enroll -u http://$1:$2@localhost:7054 -M ${NodeDir}/$3s/$1/msp
    set +x
    echo 
    
    # rename
    mv ${NodeDir}/$3s/$1/msp/cacerts/*.pem ${NodeDir}/$3s/$1/msp/cacerts/ca.$4-cert.pem
    mkdir -p ${NodeDir}/$3s/$1/msp/tlscacerts
    cp ${NodeDir}/$3s/$1/msp/cacerts/*.pem ${NodeDir}/$3s/$1/msp/tlscacerts/tlsca.$4-cert.pem
    
    # 1.2.create org msp and ca and tls
    cp ${NodeDir}/$3s/$1/msp/cacerts/*.pem ${NodeDir}/msp/cacerts
    cp ${NodeDir}/$3s/$1/msp/tlscacerts/*.pem ${NodeDir}/msp/tlscacerts
    cp ${NodeDir}/$3s/$1/msp/cacerts/*.pem ${NodeDir}/ca
    cp ${NodeDir}/$3s/$1/msp/tlscacerts/*.pem ${NodeDir}/tlsca

    # 1.2.create peer tls
    mkdir -p ${NodeDir}/$3s/$1/tls
    cp ${NodeDir}/$3s/$1/msp/cacerts/*.pem ${NodeDir}/$3s/$1/tls/ca.crt
    cp ${NodeDir}/$3s/$1/msp/keystore/*_sk ${NodeDir}/$3s/$1/tls/server.key
    cp ${NodeDir}/$3s/$1/msp/signcerts/*.pem ${NodeDir}/$3s/$1/tls/server.crt


    # 1.3.register peer admin
    set -x
    ${FABRIC_CA_CLIENT_HOME}/fabric-ca-client register --id.type $3 --id.name Admin@$4 --id.secret $2 --id.affiliation $4 --id.attrs '"hf.Registrar.Roles=ADMIN","hf.Revoker=true"'
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to register ..."
        exit 1
    fi
    echo 

    set -x
    ${FABRIC_CA_CLIENT_HOME}/fabric-ca-client enroll -u http://$1:$2@localhost:7054 -M ${NodeDir}/users/Admin@$4/msp
    set +x
    echo 
    
    # rename
    mv ${NodeDir}/users/Admin@$4/msp/cacerts/*.pem ${NodeDir}/users/Admin@$4/msp/cacerts/ca.$4-cert.pem
    mkdir -p ${NodeDir}/users/Admin@$4/msp/tlscacerts
    cp ${NodeDir}/users/Admin@$4/msp/cacerts/*.pem ${NodeDir}/users/Admin@$4/msp/tlscacerts/tlsca.$4-cert.pem
    
    # 1.4.create orderer user tls
    mkdir -p ${NodeDir}/users/Admin@$4/tls
    cp ${NodeDir}/users/Admin@$4/msp/tlscacerts/*.pem ${NodeDir}/users/Admin@$4/tls/ca.crt
    cp ${NodeDir}/users/Admin@$4/msp/keystore/*_sk ${NodeDir}/users/Admin@$4/tls/server.key
    cp ${NodeDir}/users/Admin@$4/msp/signcerts/*.pem ${NodeDir}/users/Admin@$4/tls/server.crt
    mkdir ${NodeDir}/users/Admin@$4/msp/admincerts
    mkdir ${NodeDir}/$3s/$1/msp/admincerts
    cp ${NodeDir}/users/Admin@$4/msp/signcerts/*.pem ${NodeDir}/users/Admin@$4/msp/admincerts
    cp ${NodeDir}/users/Admin@$4/msp/admincerts/*.pem ${NodeDir}/msp/admincerts
    cp ${NodeDir}/users/Admin@$4/msp/admincerts/*.pem ${NodeDir}/$3s/$1/msp/admincerts
    
}

Start
Admin
RegisterNode orderer.36sn.com abc123 orderer 36sn.com ORDERER
RegisterNode peer0.org1.36sn.com abc123 peer org1.36sn.com PEER
Stop