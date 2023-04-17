// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Test } from "forge-std/Test.sol";
import { console2 as console } from "forge-std/console2.sol";

import { ZuzaluOracle } from "../src/ZuzaluOracle.sol";
import { Backend } from "../src/Backend.sol";

/// TODO: use ffi to call out to getProof.ts to create a proof
contract ProofGeneration {
    function create() external {}
}

contract ZuzaluOracleTest is Test {
    Backend internal backend;
    ZuzaluOracle internal oracle;
    // owner of oracle
    address internal alice;

    function setUp() public {
        alice = makeAddr("alice");
        backend = new Backend();
        Backend.Group memory group = backend.group();
        address verifier = _verifier();

        oracle = new ZuzaluOracle(alice, group.root, group.depth, verifier);
    }

    function _verifier() internal returns (address) {
        uint256 chainid = block.chainid;
        if (chainid == 5) {
            return 0xb908Bcb798e5353fB90155C692BddE3b4937217C;
        }
        revert("unknown chainid");
    }

    // need to create proof
    function test_foo() external skipWhenNotForking {
        console.log(address(oracle));
    }
}
