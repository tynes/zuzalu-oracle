// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {SemaphoreVerifier} from "@semaphore-protocol/contracts/base/SemaphoreVerifier.sol";
import {Owned} from "solmate/auth/Owned.sol";

/// @title An on-chain oracle for the Zuzalu groups
/// @author Mark Tyneway <mark.tyneway@gmail.com>
/// @author Odysseas.eth <odyslam@gmail.com>
contract ZuzaluOracle is Owned {

    enum Groups {
        // Dummy value so that groups have the official numbering (1-4)
        None,
        Participants,
        Residents,
        Visitors,
        Organizers
    }

    /// @notice
    event Update(uint256 root, uint256 depth);

    /// @notice The group is not one of the groups in the Groups enum
    error InvalidGroup();

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

    /// @notice The address of the Semaphore verifier contract
    address public immutable VERIFIER;

    constructor(address _owner, address _verifier) Owned(_owner) {
        VERIFIER = _verifier;
    }

    /*//////////////////////////////////////////////////////////////
                              UPDATE GROUP
    //////////////////////////////////////////////////////////////*/

    /// @notice Updates the root and depth of a group
    /// @param root The new root
    /// @param _depth The new depth
    /// @param _group The group to update
    /// @dev The group must be one of the groups in the Groups enum which are defined in the following
    /// order (0: Visitors, 1: Residents, 2: Organizers, 3: Participants)
    function updateGroup(uint256 root, uint256 _depth, Groups _group) public onlyOwner {
        if (_group == Groups.Visitors) {
            _updateVisitors(root, _depth);
        } else if (_group == Groups.Residents) {
            _updateResidents(root, _depth);
        } else if (_group == Groups.Organizers) {
            _updateOrganizers(root, _depth);
        } else if (_group == Groups.Participants) {
            _updateParticipants(root, _depth);
        } else {
            revert InvalidGroup();
        }
    }

    /// @notice Updates the roots and depths of all the groups
    /// @param _roots An array of roots for each group
    /// @param _depths An array of depths for each group
    /// @dev The order of the roots and depths must match the order of the groups. If you don't want to update
    /// a group, pass in 0 for the root.
    function updateGroups(uint256[4] calldata _roots, uint256[4] calldata _depths) public onlyOwner {
        if(_roots[0] != 0){ 
            _updateVisitors(_roots[0], _depths[0]);
        }
        if (_roots[1] != 0) {
            _updateResidents(_roots[1], _depths[1]);
        }
        if (_roots[2] !=0){ 
            _updateOrganizers(_roots[2], _depths[2]);
        }
        if (_roots[3] != 0) {
            _updateParticipants(_roots[3], _depths[3]);
        }
    }

    /// @notice The internal function that updates the root and depth of the "visitors" group
    /// @param _root The new root
    /// @param _depth The new depth
    /// @dev The depth is stored in a mapping, so that we can easily get the depth of the current and all previous roots
    function _updateVisitors(uint256 _root, uint256 _depth) internal {
        $visitorRoots.push(_root);
        $visitorsToDepth[_root] = _depth;
        emit Update(_root, _depth);
    }

    /// @notice The internal function that updates the root and depth of the "residents" group
    /// @param _root The new root
    /// @param _depth The new depth
    /// @dev The depth is stored in a mapping, so that we can easily get the depth of the current and all previous roots
    function _updateResidents(uint256 _root, uint256 _depth) internal {
        $residentRoots.push(_root);
        $residentsToDepth[_root] = _depth;
        emit Update(_root, _depth);
    }

    /// @notice The internal function that updates the root and depth of the "organizers" group
    /// @param _root The new root
    /// @param _depth The new depth
    /// @dev The depth is stored in a mapping, so that we can easily get the depth of the current and all previous roots
    function _updateOrganizers(uint256 _root, uint256 _depth) internal {
        $organizerRoots.push(_root);
        $organizersToDepth[_root] = _depth;
        emit Update(_root, _depth);
    }

    /// @notice The internal function that updates the root and depth of the "participants" group
    /// @param _root The new root
    /// @param _depth The new depth
    /// @dev The depth is stored in a mapping, so that we can easily get the depth of the current and all previous roots
    function _updateParticipants(uint256 _root, uint256 _depth) internal {
        $participantRoots.push(_root);
        $participantsToDepth[_root] = _depth;
        emit Update(_root, _depth);
    }

    /*//////////////////////////////////////////////////////////////
                                 VERIFY
    //////////////////////////////////////////////////////////////*/

    /// @notice Verifies a Semaphore proof for a particular signal and group. It returns true if the proof is valid, and false otherwise.
    /// @param _nullifierHash The hash of the nullifier
    /// @param _signal The signal to verify
    /// @param _externalNullifier The external nullifier
    /// @param _proof The proof to verify
    /// @param _group The group to verify the proof for { None, Visitors, Residents, Organizers, Participants }
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
        } else {
            revert InvalidGroup();
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

    /// @notice Verifies a Semaphore proof for a particular signal and group. The group is specified by the root and depth 
    /// which is not one of the groups defined in the contract. It returns true if the proof is valid, and false otherwise.
    /// @param _root The root of the merkle tree
    /// @param _depth The depth of the merkle tree
    /// @param _nullifierHash The hash of the nullifier
    /// @param _signal The signal to verify
    /// @param _externalNullifier The external nullifier
    /// @param _proof The proof to verify
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

    /// @notice The internal function that verifies a Semaphore proof. It calls the deployed Semaphore contract that makes the actual verification.
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
