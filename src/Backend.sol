// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { CommonBase } from "forge-std/Base.sol";

contract Backend is CommonBase {
    struct Group {
      uint256 id;
      string name;
      uint256[] members;
      uint256 depth;
      uint256 root;
    }

    Group internal _group;

    function group() external returns (Group memory) {
      if (_group.members.length == 0) {
        string[] memory inputs = new string[](3);
        inputs[0] = "npx";
        inputs[1] = "ts-node";
        inputs[2] = "ffi/getGroup.ts";
        bytes memory res = vm.ffi(inputs);

        (
          uint256 _id,
          string memory _name,
          uint256[] memory _members,
          uint256 _depth,
          uint256 _root
        ) = abi.decode(res, (uint256, string, uint256[], uint256, uint256));

        _group = Group({
          id: _id,
          name: _name,
          members: _members,
          depth: _depth,
          root: _root
        });
      }

      return _group;
    }
}

