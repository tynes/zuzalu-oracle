#!/bin/bash

VERIFIER_ADDRESS=0xb908Bcb798e5353fB90155C692BddE3b4937217C

ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)
BALANCE=$(cast balance --rpc-url $ETH_RPC_URL $ADDRESS)
ETH_BALANCE=$(cast --to-unit $BALANCE ether)

echo "$ADDRESS has $ETH_BALANCE ether"

# TODO: this should be output of the first deploy script
# and passed into the second deploy script
ORACLE_ADDRESS=0x275887D2D22d471663D58d69b9611792fFf1FEeD

forge script scripts/Deploy.s.sol \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETH_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --sig 'deployOracle(address,address,uint256)' \
  $VERIFIER_ADDRESS

forge script scripts/Deploy.s.sol \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETH_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --sig 'deployLottery(address,address,uint256)' \
  $ORACLE_ADDRESS \
  $ADDRESS \
  10
