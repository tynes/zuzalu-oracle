// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract MockVerifier {
    bool canSucceed = true;

    function success(bool _canSucceed) public {
        canSucceed = _canSucceed;
    }

    event MockVerify(uint256 root);

    function verifyProof(uint256 merkleTreeRoot, uint256, uint256, uint256, uint256[8] calldata, uint256) external {
        emit MockVerify(merkleTreeRoot);
        if (!canSucceed) {
            revert("nope");
        }
    }
}
