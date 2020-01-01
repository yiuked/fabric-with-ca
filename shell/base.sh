CHANNEL_NAME="zsjr"
APP_PATH=/home/vagrant/fabric-with-ca

export FABRIC_LOGGING_SPEC=DEBUG
export FABRIC_CFG_PATH=${APP_PATH}/config
export FABRIC_CLIENT_PATH=/home/vagrant/fabric-ca/client
export FABRIC_CA_HOME=${FABRIC_CLIENT_PATH}/ca-home
export FABRIC_TLS_HOME=${FABRIC_CLIENT_PATH}/tls-home