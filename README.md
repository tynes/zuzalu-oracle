# Zuzalu Oracle

![zuzalu logo](https://global-uploads.webflow.com/600ff0f8154936050d98ec01/64199fbf9612bf604446d6b6_zuzalu-hero.png)

This is a wrapper contract around the deploy contracts of [Semaphore](https://github.com/semaphore-protocol/semaphore), to be used by [Zuzalu](https://zuzalu.city).

# How 

The Zuzalu API offers the latest root for every group. A trusted backend cron service, named [zuzalu-updater](https://github.com/odyslam/zuzalu-updater), reads that API call and updates the on-chain stored root, so that people can generate proofs and verify them on-chain.

# Deployed Addresses TBD

- [Sepolia]()
- [Ethereum]()

# Building with Zuzalu Oracle

## Understand the Semaphore Protocol

First, make sure you understand how the proof and group system works in Semaphore. 

Check out [their docs](https://semaphore.appliedzkp.org/docs/guides/proofs)!

## As an on-chain application

1. User visits the application's website
2. The application connects to the oracle and downloads the latest root of each group
3. The user wants to perform some on-chain activity that is gated to zuzalu groups members. The application selects the group the user will verify against
4. The website calculates a URL on the Zupass API for the group, given the latest root/group combination
5. The website invokes Zupass asking for a group membership with a group URL from step 4
6. The website extracts the semaphore proof from the returned PCD and uploads it to the smart contract
7. The smart contract verifies the semaphore proof, using the oracle, and depending on the return (true|false) it decides what to do

## How to integrate in Solidity

Read the smart contract [docs](https://odyslam.github.io/zuzalu-oracle)!

Install
```Bash
yarn add zuzalu-oracle
```
and then just
```Solidity
ZuzaluOracle oracle = ZuzaluOracle(ORACLE_ADDRESS);
uint[8] proof;
// Use the latest root of group Residents
oracle.verify(0, 0, 0, proof, ZuzaluOracle.Groups.Residents);
```

## How to integrate in Typescript

1. `yarn add zuzalu-oracle`
2. Import it as follows. The example is from [zuzalu-updater](https://github.com/odyslam/zuzalu-updater)
```Typescript
import { ZuzaluOracle__factory } from 'zuzalu-oracle';

export default {
  async scheduled(
    controller: ScheduledController,
    env: Env,
    ctx: ExecutionContext
  ): Promise<void> {
    const provider = new ethers.JsonRpcProvider(env.ETH_RPC_URL);
    const wallet = new ethers.Wallet(env.ETH_PRIVATE_KEY, provider);
    const oracle = ZuzaluOracle__factory.connect(env.CONTRACT_ADDRESS, wallet);
    const latestRoots = await oracle.getLastRoots();
...
```

## License

MIT
