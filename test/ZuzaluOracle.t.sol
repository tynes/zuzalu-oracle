// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Test } from "forge-std/Test.sol";
import { console2 as console } from "forge-std/console2.sol";

import { ZuzaluOracle } from "../src/ZuzaluOracle.sol";
import { Backend } from "./utils/Backend.sol";

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

    /// @notice
    function setUp() public {
        alice = makeAddr("alice");
        backend = new Backend();
        Backend.Group memory group = backend.group();

        address verifier = _verifier();

        ZuzaluOracle.Commitment memory commitment = ZuzaluOracle.Commitment({
            root: group.root,
            depth: group.depth
        });

        oracle = new ZuzaluOracle({
            _commitment: commitment,
            _owner: alice,
            _verifier: verifier
        });
    }

    /// @notice TODO: set the code for the verifier when running locally
    function _verifier() internal view returns (address) {
        uint256 chainid = block.chainid;
        if (chainid == 5) {
            return 0xb908Bcb798e5353fB90155C692BddE3b4937217C;
        }
        revert("unknown chainid");
    }

    function _commitment(uint256 _root, uint256 _depth) internal pure returns (ZuzaluOracle.Commitment memory) {
        ZuzaluOracle.Commitment memory commitment = ZuzaluOracle.Commitment({
            root: _root,
            depth: _depth
        });
        return commitment;
    }

    function test_constructor() external {
        assertEq(oracle.owner(), alice);
        assertEq(oracle.VERIFIER(), _verifier());
    }

    function test_commitment() external {
        ZuzaluOracle.Commitment memory commitment = _commitment(1, 2);
        vm.prank(oracle.owner());
        oracle.update(commitment);

        ZuzaluOracle.Commitment memory got = oracle.commitment();

        assertTrue(got.root == commitment.root);
        assertTrue(got.depth == commitment.depth);
    }

    /// @notice
    function test_updateOnlyOwner_reverts() external skipWhenNotForking {
        ZuzaluOracle.Commitment memory commitment = _commitment(0, 0);

        address bob = makeAddr("bob");
        assertTrue(oracle.owner() != bob);

        vm.prank(bob);
        vm.expectRevert("UNAUTHORIZED");
        oracle.update(commitment);
    }
}
