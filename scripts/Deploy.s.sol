// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import {Script} from "forge-std/Script.sol";
import {ZuzaluOracle} from "../src/ZuzaluOracle.sol";
import { Lottery } from "../src/Lottery.sol";
import { console2 as console } from "forge-std/console2.sol";

contract Deploy is Script {
  function deployOracle(address verifier) public {
    vm.broadcast();
    ZuzaluOracle oracle = new ZuzaluOracle({
      _owner: msg.sender,
      _verifier: verifier
    });

    console.log("Deployed oracle at address: %s", address(oracle));
  }

  function deployLottery(address oracle, address recipient, uint256 durationInDays) public {
    uint256 duration = durationInDays * 86400;

    vm.broadcast();
    Lottery lottery = new Lottery({
      _oracle: ZuzaluOracle(oracle),
      _end: block.timestamp + duration,
      _recipient: recipient,
      _baseURI: "https://zuzalu-lottery.odyslam.workers.dev/nft/"
    });

    console.log("Deployed lottery at address: %s", address(lottery));
  }
}
