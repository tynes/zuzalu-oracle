// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import {Script} from "forge-std/Script.sol";
import {ZuzaluOracle} from "../src/ZuzaluOracle.sol";

contract Deploy {
  function deployOracle(address verifier) public {
    ZuzaluOracle oracle = new ZuzaluOracle({
      _owner: msg.sender,
      _verifier: verifier
    });
  }

  function deployLottery(address oracle, address recipient, uint256 durationInDays) public {
    Lottery lottery = new Lottery({
      _oracle: oracle,
      _end: block.timestamp + (durationInDays days),
      _recipient: recipient,
      _baseURI: "https://zuzalu-lottery.odyslam.workers.dev/nft/"
    });
  }
}
