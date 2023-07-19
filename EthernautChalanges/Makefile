all: deploy

include .env

deploy:
	forge script script/${CONTRACT} --rpc-url ${SEPOLIA_RPC_URL} --private-key ${PRIVATE_KEY} --broadcast