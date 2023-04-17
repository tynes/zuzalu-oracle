// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { SemaphoreVerifier } from "./SemaphoreVerifier.sol";
import { Owned } from "solmate/auth/Owned.sol";

/*
function register(address, proof) external {
  if (ORACLE.verify(proof)) {
    residents[address] = true
  }
}

modifier onlyResident() {
  ...
}
*/

contract ZuzaluOracle is Owned {
    event Update(uint256 root, uint256 depth);

    uint256 public root;
    uint256 public depth;
    address immutable public VERIFIER;

    constructor(address _owner, uint256 _root, uint256 _depth, address _verifier) Owned(_owner) {
        VERIFIER = _verifier;
        _update(_root, _depth);
    }

    function update(uint256 _root, uint256 _depth) onlyOwner public {
        _update(_root, _depth);
    }

    function _update(uint256 _root, uint256 _depth) internal {
        root = _root;
        depth = _depth;
        emit Update(_root, depth);
    }

    function verify(
        uint256 _nullifierHash,
        uint256 _signal,
        uint256 _externalNullifier,
        uint256[8] calldata _proof
    ) external returns (bool) {
        try SemaphoreVerifier(VERIFIER).verifyProof({
            merkleTreeRoot: root,
            nullifierHash: _nullifierHash,
            signal: _signal,
            externalNullifier: _externalNullifier,
            proof: _proof,
            merkleTreeDepth: depth
        }) {
            return true;
        } catch {
            return false;
        }
    }
}
