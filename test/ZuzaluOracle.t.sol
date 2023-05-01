// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {Test} from "forge-std/Test.sol";
import {MockVerifier} from "./utils/MockVerifier.sol";
import {ZuzaluOracle} from "../src/ZuzaluOracle.sol";

contract ZuzaluOracleTest is Test {
    ZuzaluOracle oracle;
    MockVerifier verifier;
    address owner;

    function setUp() public {
        verifier = new MockVerifier();
        owner = vm.addr(1);
        oracle = new ZuzaluOracle(owner, address(verifier));
    }

    function test_success_contructorSetsVars() public {
        assertEq(oracle.owner(), owner);
        assertEq(oracle.VERIFIER(), address(verifier));
        uint256[4] memory initArray = [uint256(1), uint256(1), uint256(1), uint256(1)];
        uint256[4] memory roots = oracle.getLastRoots();
        assertEq(roots[0], initArray[0]);
        assertEq(roots[1], initArray[1]);
        assertEq(roots[2], initArray[2]);
        assertEq(roots[3], initArray[3]);
    }

    function testFuzz_success_updateGroupsAndGetLastDepthsAndRoots(uint256[4] memory roots, uint256[4] memory depths)
        public
    {
        vm.assume(roots[0] != 0 && roots[1] != 0 && roots[2] != 0 && roots[3] != 0);
        vm.prank(owner);
        oracle.updateGroups(roots, depths);

        uint256[4] memory newRoots = oracle.getLastRoots();
        assertEq(newRoots[0], roots[0]);
        assertEq(newRoots[1], roots[1]);
        assertEq(newRoots[2], roots[2]);
        assertEq(newRoots[3], roots[3]);

        uint256[4] memory newDepths = oracle.getLastDepths();
        assertEq(newDepths[0], depths[0]);
        assertEq(newDepths[1], depths[1]);
        assertEq(newDepths[2], depths[2]);
        assertEq(newDepths[3], depths[3]);
    }

    event MockVerify(uint256 root);

    function testFuzz_success_verifyHistoricRoots(uint256[4] memory roots, uint256[4] memory depths) public {
        vm.assume(roots[0] != 0 && roots[1] != 0 && roots[2] != 0 && roots[3] != 0);
        vm.startPrank(owner);
        oracle.updateGroups(roots, depths);
        roots[1] = 5;
        oracle.updateGroups(roots, depths);
        roots[1] = 10;
        oracle.updateGroups(roots, depths);
        roots[1] = 15;
        oracle.updateGroups(roots, depths);
        vm.stopPrank();
        // It will succeed on the first try
        verifier.success(true);
        uint256[8] memory proof;
        vm.expectEmit(false, false, false, true);
        emit MockVerify(roots[1]);
        assert(oracle.verify(0, 0, 0, proof, ZuzaluOracle.Groups.Residents));

        // After 3 attempts, it will return false. It can verify up to 2 roots back + latest.
        verifier.success(false);
        for (uint256 i; i < 3; i++) {
            vm.expectEmit(false, false, false, true);
            // It should first attempt to verify using the latest root (15) and then
            // go back to 10 and 5. These roots are the 3 latest roots of the group Residents.
            emit MockVerify((5 * 3 - 5 * i));
        }
        assert(!oracle.verify(0, 0, 0, proof, ZuzaluOracle.Groups.Residents));
    }
}
