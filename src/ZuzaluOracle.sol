// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {ISemaphoreVerifier} from "@semaphore-protocol/contracts/interfaces/ISemaphoreVerifier.sol";
import {Owned} from "solmate/auth/Owned.sol";

/// @title A wrapper contract around the Semaphore Verifier that is used by Zuzalu to verify it's members
/// @author Mark Tyneway <mark.tyneway@gmail.com>
/// @author Odysseas.eth <odyslam@gmail.com>
contract ZuzaluOracle is Owned {

    string constant internal VERSION = "0.0.1";

    /// The official groups by Zuzalu as defined and used in the backend
    enum Groups
    // Dummy value so that groups have the official numbering (1-4)
    {
        None,
        Participants,
        Residents,
        Visitors,
        Organizers
    }

    /// @notice The groups have been updated with new latest roots and depths
    event UpdateGroups(uint256[4] roots, uint256[4] depths);
    /// @notice A new succesful verification has been made for a particular Zuzalu group and signal
    event Verify(uint256 indexed signal, uint256 indexed root, Groups indexed _group);

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
        _initArrays();
    }

    /// @notice Initialize the arrays so that the getLastRoots() function does not revert and the backend
    /// does not have to implement a special case for the first time the contract is deployed
    function _initArrays() internal {
        $visitorRoots.push(1);
        $residentRoots.push(1);
        $organizerRoots.push(1);
        $participantRoots.push(1);
    }

    /// @notice Updates the roots and depths of all the groups
    /// @param _roots An array of roots for each group
    /// @param _depths An array of depths for each group
    /// @dev The order of the roots and depths must match the order of the groups. If you don't want to update
    /// a group, pass in 0 for the root.
    function updateGroups(uint256[4] calldata _roots, uint256[4] calldata _depths) public onlyOwner {
        if (_roots[0] != 0) {
            _update($visitorRoots, $visitorsToDepth, _roots[0], _depths[0]);
        }
        if (_roots[1] != 0) {
            _update($residentRoots, $residentsToDepth, _roots[1], _depths[1]);
        }
        if (_roots[2] != 0) {
            _update($organizerRoots, $organizersToDepth, _roots[2], _depths[2]);
        }
        if (_roots[3] != 0) {
            _update($participantRoots, $participantsToDepth, _roots[3], _depths[3]);
        }
        emit UpdateGroups(_roots, _depths);
    }

    /// @notice Updates the roots and depths of a particular group
    function _update(
        uint256[] storage _roots,
        mapping(uint256 => uint256) storage _toDepth,
        uint256 _root,
        uint256 _depth
    ) internal {
        _roots.push(_root);
        _toDepth[_root] = _depth;
    }

    /*//////////////////////////////////////////////////////////////
                                 VERIFY
    //////////////////////////////////////////////////////////////*/

    /// @notice Verifies a Semaphore proof for a particular signal and group. It returns true if the proof is valid, and false otherwise. It will check against
    /// historic roots in case the latest root doesn't work. As the latest root may be updated between proof generation and verification, we want to offer a better
    /// UX to the users by enabling by default to fall to check up to a limit of previous roots.
    /// @notice It will check up to 2 roots in the past (latest + 2 roots).
    /// @dev The backend updates the root every few hours, so at worse case the user will generate the proof and right away the backend will update the latest root. By checking the historic roots as well, we allow the user to still use the proof for a small extra cost in gas.
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
    ) external returns (bool) {
        uint256 historicIndex = 1;
        // Note: We have a side-effect in the arg for some small gas saving
        while (!_verifyHistoric(_nullifierHash, _signal, _externalNullifier, _proof, _group, historicIndex++)) {
            if (historicIndex > 3) {
                return false;
            }
        }
        return true;
    }

    /// @notice Verifies a Semaphore proof for a particular signal and group. It returns true if the proof is valid, and false otherwise. 
    /// @dev It will not check the latest root, but a root in the past, as specified by the _historicRootIndex.
    /// @param _nullifierHash The hash of the nullifier
    /// @param _signal The signal to verify
    /// @param _externalNullifier The external nullifier
    /// @param _proof The proof to verify
    /// @param _historicRootIndex The index of the array that contains the roots for the specific group.
    /// @param _group The group to verify the proof for { None, Visitors, Residents, Organizers, Participants }
    function verify(
        uint256 _nullifierHash,
        uint256 _signal,
        uint256 _externalNullifier,
        uint256[8] calldata _proof,
        uint256 _historicRootIndex,
        Groups _group
    ) external returns (bool) {
        return _verifyHistoric(_nullifierHash, _signal, _externalNullifier, _proof, _group, _historicRootIndex);
    }


    /// @notice Verifies a Semaphore proof for a particular signal and group. It returns true if the proof is valid, and false otherwise. It will also return
    /// false if the index is out of bounds of the array for the specific group.
    /// @param _nullifierHash The hash of the nullifier
    /// @param _signal The signal to verify
    /// @param _externalNullifier The external nullifier
    /// @param _proof The proof to verify
    /// @param _historicIndex The index of the array that contains the roots for the specific group.
    /// @param _group The group to verify the proof for { None, Visitors, Residents, Organizers, Participants }
    function _verifyHistoric(
        uint256 _nullifierHash,
        uint256 _signal,
        uint256 _externalNullifier,
        uint256[8] calldata _proof,
        Groups _group,
        uint256 _historicIndex
    ) internal returns (bool) {
        uint256 root;
        uint256 depth;
        if (_group == Groups.Visitors) {
            if ($visitorRoots.length < _historicIndex) {
                return false;
            }
            (root, depth) = _getRootAndDepth($visitorRoots, _historicIndex, $visitorsToDepth);
        } else if (_group == Groups.Residents) {
            if ($residentRoots.length < _historicIndex) {
                return false;
            }
            (root, depth) = _getRootAndDepth($residentRoots, _historicIndex, $residentsToDepth);
        } else if (_group == Groups.Organizers) {
            if ($organizerRoots.length < _historicIndex) {
                return false;
            }
            (root, depth) = _getRootAndDepth($organizerRoots, _historicIndex, $organizersToDepth);
        } else if (_group == Groups.Participants) {
            if ($participantRoots.length < _historicIndex) {
                return false;
            }
            (root, depth) = _getRootAndDepth($participantRoots, _historicIndex, $participantsToDepth);
        } else {
            revert InvalidGroup();
        }
        emit Verify(_signal, root, _group);
        return _verify({
            _root: root,
            _depth: depth,
            _nullifierHash: _nullifierHash,
            _signal: _signal,
            _externalNullifier: _externalNullifier,
            _proof: _proof
        });
    }

    ///@notice Get the root and and the depth from the data structures that are passed as inputs
    /// @dev The function accepts a storage pointer, not the actual data
    /// @param roots The roots array
    /// @param index The index of the root to get
    /// @param depths The depths mapping
    function _getRootAndDepth(uint256[] storage roots, uint256 index, mapping(uint256 => uint256) storage depths)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 root = roots[roots.length - index];
        uint256 depth = depths[root];
        return (root, depth);
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
    ) external returns (bool) {
        return _verify({
            _root: _root,
            _depth: _depth,
            _nullifierHash: _nullifierHash,
            _signal: _signal,
            _externalNullifier: _externalNullifier,
            _proof: _proof
        });
    }

    /// @notice Thin wrapper arround the SemaphoreVerifier contract's verifyProof function
    function _verify(
        uint256 _root,
        uint256 _depth,
        uint256 _nullifierHash,
        uint256 _signal,
        uint256 _externalNullifier,
        uint256[8] calldata _proof
    ) internal returns (bool) {
        (bool success,) = VERIFIER.call(
            abi.encodeWithSelector(
                ISemaphoreVerifier.verifyProof.selector,
                _root,
                _nullifierHash,
                _signal,
                _externalNullifier,
                _proof,
                _depth
            )
        );
        return success;
    }

    /*//////////////////////////////////////////////////////////////
                             GETTERS
    //////////////////////////////////////////////////////////////*/
    
    function version() public pure returns (string memory) {
        return VERSION;
    }

    /// @notice Returns the current root of the group provided in the argument
    /// @param _group The group to get the root for { None, Visitors, Residents, Organizers, Participants }
    /// @return root The current root of the group
    function getLastRoot(Groups _group) external view returns (uint256) {
        if (_group == Groups.Participants) {
            return $participantRoots[$participantRoots.length - 1];
        } else if (_group == Groups.Organizers) {
            return $organizerRoots[$organizerRoots.length - 1];
        } else if (_group == Groups.Residents) {
            return $residentRoots[$residentRoots.length - 1];
        } else if (_group == Groups.Visitors) {
            return $visitorRoots[$visitorRoots.length - 1];
        } else {
            revert InvalidGroup();
        }
    }

    /// @notice Returns the latest root of all the groups in an array
    /// @return roots The latest roots of all the groups [participants, residents, visitors, organizers]
    function getLastRoots() external view returns (uint256[4] memory) {
        uint256[4] memory roots;
        roots[0] = $visitorRoots[$visitorRoots.length - 1];
        roots[1] = $residentRoots[$residentRoots.length - 1];
        roots[2] = $organizerRoots[$organizerRoots.length - 1];
        roots[3] = $participantRoots[$participantRoots.length - 1];
        return roots;
    }

    function getLastDepths() external view returns (uint256[4] memory) {
        uint256[4] memory depths;
        depths[0] = $visitorsToDepth[$visitorRoots[$visitorRoots.length - 1]];
        depths[1] = $residentsToDepth[$residentRoots[$residentRoots.length - 1]];
        depths[2] = $organizersToDepth[$organizerRoots[$organizerRoots.length - 1]];
        depths[3] = $participantsToDepth[$participantRoots[$participantRoots.length - 1]];
        return depths;
    }
}
