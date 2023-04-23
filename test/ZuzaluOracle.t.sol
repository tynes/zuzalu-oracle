// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {ZuzaluOracle} from "../src/ZuzaluOracle.sol";
import {SemaphoreVerifier} from "@semaphore-protocol/contracts/base/SemaphoreVerifier.sol";
import {Backend} from "./utils/Backend.sol";

/// TODO: use ffi to call out to getProof.ts to create a proof
contract ProofGeneration {
    function create() external {}
}

contract ZuzaluOracleTest is Test {
    /// @notice
    Backend internal backend;
    /// @notice
    ZuzaluOracle internal oracle;
    /// @notice owner of the oracle
    address internal alice;

    SemaphoreVerifier internal verifier;
    address verifierAddress;

    /// @notice
    function setUp() public {
        alice = makeAddr("alice");
        backend = new Backend();
        uint256 groupId = uint256(ZuzaluOracle.Groups.Participants);
        Backend.Group memory group = backend.group(groupId);

        verifier = new SemaphoreVerifier();
        verifierAddress = address(verifier);

        uint256 root = group.root;
        uint256 depth = group.depth;

        oracle = new ZuzaluOracle({
            _owner: alice,
            _verifier: verifierAddress
        });
    }

    function test_constructor() external {
        assertEq(oracle.owner(), alice);
        assertEq(oracle.VERIFIER(), verifierAddress);
    }

    /// @notice
    function test_updateOnlyOwner_reverts() external skipWhenNotForking {
        address bob = makeAddr("bob");
        assertTrue(oracle.owner() != bob);

        vm.prank(bob);
        vm.expectRevert("UNAUTHORIZED");
        oracle.updateGroup(0, 1, ZuzaluOracle.Groups.Participants);
    }
}
