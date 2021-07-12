#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error
set -e

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
starttime=$(date +%s)
CC_SRC_LANGUAGE=${1:-"go"}
CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`
if [ "$CC_SRC_LANGUAGE" = "go" -o "$CC_SRC_LANGUAGE" = "golang"  ]; then
	CC_RUNTIME_LANGUAGE=golang
	CC_SRC_PATH=github.com/myfirstcc
elif [ "$CC_SRC_LANGUAGE" = "javascript" ]; then
	CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
	CC_SRC_PATH=/opt/gopath/src/github.com/fabcar/javascript
elif [ "$CC_SRC_LANGUAGE" = "typescript" ]; then
	CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
	CC_SRC_PATH=/opt/gopath/src/github.com/fabcar/typescript
	echo Compiling TypeScript code into JavaScript ...
	pushd ../chaincode/fabcar/typescript
	npm install
	npm run build
	popd
	echo Finished compiling TypeScript code into JavaScript
else
	echo The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script
	echo Supported chaincode languages are: go, javascript, and typescript
	exit 1
fi


# clean the keystore
rm -rf ./hfc-key-store

# launch network; create channel and join peer to channel
cd ../basic-network
./start.sh

# Now launch the CLI container in order to install, instantiate chaincode
# and prime the ledger with our 10 cars
docker-compose -f ./docker-compose.yml up -d cli
docker ps -a

docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode install -n myfirstcc -v 1.0 -p "$CC_SRC_PATH" -l "$CC_RUNTIME_LANGUAGE"
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n myfirstcc -l "$CC_RUNTIME_LANGUAGE" -v 1.0 -c '{"Args":[]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
sleep 10
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n myfirstcc -c '{"function":"set","Args":["Asset1","500"]}'
sleep 5
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n myfirstcc -c '{"function":"get","Args":["Asset1"]}'



