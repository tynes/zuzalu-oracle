// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {CommonBase} from "forge-std/Base.sol";
import {ZuzaluOracle} from "../../src/ZuzaluOracle.sol";

contract Backend is CommonBase {
    struct Group {
        uint256 id;
        string name;
        uint256[] members;
        uint256 depth;
        uint256 root;
    }

    Group internal _group;

    function group(uint256 _groupId) external returns (Group memory) {
        string memory groupNumber = vm.toString(_groupId);
        if (_group.members.length == 0) {
            string[] memory inputs = new string[](4);
            inputs[0] = "npx";
            inputs[1] = "ts-node";
            inputs[2] = "ffi/getGroup.ts";
            inputs[3] = groupNumber;
            bytes memory res = vm.ffi(inputs);

            (uint256 _id, string memory _name, uint256[] memory _members, uint256 _depth, uint256 _root) =
                abi.decode(res, (uint256, string, uint256[], uint256, uint256));

            _group = Group({id: _id, name: _name, members: _members, depth: _depth, root: _root});
        }

        return _group;
    }
}
