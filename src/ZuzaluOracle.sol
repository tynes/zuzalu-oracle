// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {SemaphoreVerifier} from "@semaphore-protocol/contracts/base/SemaphoreVerifier.sol";
import {Owned} from "solmate/auth/Owned.sol";

/// @title
contract ZuzaluOracle is Owned {
    /// @notice
    struct Commitment {
        uint256 root;
        uint256 depth;
    }

    enum Groups {
        Visitors,
        Residents,
        Organizers,
        Participants
    }

    /// @notice
    event Update(uint256 root, uint256 depth);

    /// @notice
    error NotCanonical(uint256);

    /// @notice An array of roots for the "visitors" group
    uint256[] $visitorRoots;
    /// @notice An arry of roots for the "residents" group
    uint256[] $residentRoots;
    /// @notice An array of roots for the "organizers" group
    uint256[] $organizerRoots;
    /// @notice An array of roots for the "participants" group
    uint256[] $participantRoots;

    /// @notice A mapping of roots to their depth for the "visitors" groups
    mapping(uint256 => uint256) public $visitorsToDepth;
    /// @notice A mapping of roots to their depth for the "residents" groups
    mapping(uint256 => uint256) public $residentsToDepth;
    /// @notice A mapping of roots to their depth for the "organizers" groups
    mapping(uint256 => uint256) public $organizersToDepth;
    /// @notice A mapping of roots to their depth for the "participants" groups
    mapping(uint256 => uint256) public $participantsToDepth;

    /// @notice
    address public immutable VERIFIER;

    /// @notice
    constructor(address _owner, address _verifier) Owned(_owner) {
        VERIFIER = _verifier;
    }

    /*//////////////////////////////////////////////////////////////
                              UPDATE GROUP
    //////////////////////////////////////////////////////////////*/

    function updateGroup(uint256 root, uint256 _depth, Groups _group) public onlyOwner {
        if (_group == Groups.Visitors) {
            _updateVisitors(root, _depth);
        } else if (_group == Groups.Residents) {
            _updateResidents(root, _depth);
        } else if (_group == Groups.Organizers) {
            _updateOrganizers(root, _depth);
        } else if (_group == Groups.Participants) {
            _updateParticipants(root, _depth);
        }
    }

    function updateGroups(uint256[4] calldata _roots, uint256[4] calldata _depths) public onlyOwner {
        _updateVisitors(_roots[0], _depths[0]);
        _updateResidents(_roots[1], _depths[1]);
        _updateOrganizers(_roots[2], _depths[2]);
        _updateParticipants(_roots[3], _depths[3]);
    }

    function _updateVisitors(uint256 _root, uint256 _depth) internal {
        $visitorRoots.push(_root);
        $visitorsToDepth[_root] = _depth;
        emit Update(_root, _depth);
    }

    function _updateResidents(uint256 _root, uint256 _depth) internal {
        $residentRoots.push(_root);
        $residentsToDepth[_root] = _depth;
        emit Update(_root, _depth);
    }

    function _updateOrganizers(uint256 _root, uint256 _depth) internal {
        $organizerRoots.push(_root);
        $organizersToDepth[_root] = _depth;
        emit Update(_root, _depth);
    }

    function _updateParticipants(uint256 _root, uint256 _depth) internal {
        $participantRoots.push(_root);
        $participantsToDepth[_root] = _depth;
        emit Update(_root, _depth);
    }

    /*//////////////////////////////////////////////////////////////
                                 VERIFY
    //////////////////////////////////////////////////////////////*/

    /// @notice
    function verify(
        uint256 _nullifierHash,
        uint256 _signal,
        uint256 _externalNullifier,
        uint256[8] calldata _proof,
        Groups _group
    ) external view returns (bool) {
        uint256 root;
        uint256 depth;
        if (_group == Groups.Visitors) {
            root = $visitorRoots[$visitorRoots.length - 1];
            depth = $visitorsToDepth[root];
        } else if (_group == Groups.Residents) {
            root = $residentRoots[$visitorRoots.length - 1];
            depth = $residentsToDepth[root];
        } else if (_group == Groups.Organizers) {
            root = $organizerRoots[$visitorRoots.length - 1];
            depth = $organizersToDepth[root];
        } else if (_group == Groups.Participants) {
            root = $participantRoots[$visitorRoots.length - 1];
            depth = $participantsToDepth[root];
        }
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
        uint256 _depth,
        uint256 _nullifierHash,
        uint256 _signal,
        uint256 _externalNullifier,
        uint256[8] calldata _proof
    ) external view returns (bool) {
        return _verify({
            _root: _root,
            _depth: _depth,
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
