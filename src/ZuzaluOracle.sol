// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { SemaphoreVerifier } from "@semaphore-protocol/contracts/base/SemaphoreVerifier.sol";
import { Owned } from "solmate/auth/Owned.sol";

/// @title
contract ZuzaluOracle is Owned {
    /// @notice
    struct Commitment {
        uint256 root;
        uint256 depth;
    }

    /// @notice
    event Update(uint256 root, uint256 depth);

    /// @notice
    error NotCanonical(uint256);

    /// @notice
    Commitment private _latestCommitment;

    /// @notice root -> depth
    mapping(uint256 => uint256) public commitments;

    /// @notice
    address immutable public VERIFIER;

    /// @notice
    constructor(Commitment memory _commitment, address _owner, address _verifier) Owned(_owner) {
        VERIFIER = _verifier;
        _update(_commitment);
    }

    /// @notice
    function commitment() public view returns (Commitment memory) {
        return _latestCommitment;
    }

    /// @notice
    function update(Commitment memory _commitment) onlyOwner public {
        _update(_commitment);
    }

    /// @notice
    function _update(Commitment memory _commitment) internal {
        _latestCommitment = _commitment;
        commitments[_commitment.root] = _commitment.depth;
        emit Update(_commitment.root, _commitment.depth);
    }

    /// @notice
    function verify(
        uint256 _nullifierHash,
        uint256 _signal,
        uint256 _externalNullifier,
        uint256[8] calldata _proof
    ) external view returns (bool) {
        uint256 root = _latestCommitment.root;
        uint256 depth = _latestCommitment.depth;

        return _verify({
            _root: root,
            _depth: depth,
            _nullifierHash: _nullifierHash,
            _signal: _signal,
            _externalNullifier: _externalNullifier,
            _proof: _proof
        });
    }

    /// @notice
    function verifyUnsafe(
        uint256 _root,
        uint256 _nullifierHash,
        uint256 _signal,
        uint256 _externalNullifier,
        uint256[8] calldata _proof
    ) external view returns (bool) {
        uint256 depth = commitments[_root];
        if (depth == 0) revert NotCanonical(_root);

        return _verify({
            _root: _root,
            _depth: depth,
            _nullifierHash: _nullifierHash,
            _signal: _signal,
            _externalNullifier: _externalNullifier,
            _proof: _proof
        });
    }

    /// @notice
    function _verify(
        uint256 _root,
        uint256 _depth,
        uint256 _nullifierHash,
        uint256 _signal,
        uint256 _externalNullifier,
        uint256[8] calldata _proof
    ) internal view returns (bool) {
        try SemaphoreVerifier(VERIFIER).verifyProof({
            merkleTreeRoot: _root,
            nullifierHash: _nullifierHash,
            signal: _signal,
            externalNullifier: _externalNullifier,
            proof: _proof,
            merkleTreeDepth: _depth
        }) {
            return true;
        } catch {
            return false;
        }
    }
}
