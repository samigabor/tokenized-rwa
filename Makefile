-include .env

.PHONY: deploy

deploy :; @forge script script/DeployTokenizedRWA.s.sol --private-key ${PRIVATE_KEY} --rpc-url ${SEPOLIA_RPC_URL} --etherscan-api-key ${ETHERSCAN_KEY} --priority-gas-price 1 --verify --broadcast

# forge verify-contract \
# --chain-id 11155111 \
# --watch \
# --constructor-args $(cast abi-encode "constructor(bytes32,uint8,uint64,uint64,address,uint32,uint256)" 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000 0 1715713702 2656 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0 300000 100000000000000000000) \
# --etherscan-api-key $ETHERSCAN_KEY \
# --optimizer-runs 200 \
# 0x1aF9647d8F51Fe57c4588540d08Aa505905d1B98 \
# src/TokenizedRWA.sol:TokenizedRWA