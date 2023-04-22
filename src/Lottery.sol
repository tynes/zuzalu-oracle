// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { ERC721 } from "solmate/tokens/ERC721.sol";
import { ZuzaluOracle } from "./ZuzaluOracle.sol";

/// @notice
contract Lottery is ERC721 {
    /// @notice
    error NotResident(address);

    /// @notice
    error InvalidProof();

    /// @notice
    error InvalidAmount();

    /// @notice
    error Ended();

    /// @notice
    error TransferFailed();

    /// @notice
    error SoulBound();

    /// @notice
    ZuzaluOracle immutable public ORACLE;

    /// @notice
    uint256 immutable public END;

    /// @notice
    address immutable public RECIPIENT;

    /// @notice
    bytes32 public random;

    /// @notice
    uint256 public totalSupply;

    /// @notice
    mapping(address => bool) public residents;

    /// @notice
    constructor(
      ZuzaluOracle _oracle,
      uint256 _end,
      address _recipient
    ) ERC721("Zuzalu Lottery", "ZLOT") {
      ORACLE = _oracle;
      RECIPIENT = _recipient;
      END = _end;
      random = keccak256(abi.encode(block.timestamp, _oracle, _end));
    }

    /// @notice
    modifier onlyResident() {
      if (!residents[msg.sender]) revert NotResident(msg.sender);
      _;
    }

    /// @notice
    function register(
        uint256 _root,
        uint256 _nullifierHash,
        uint256 _signal,
        uint256 _externalNullifier,
        uint256[8] calldata _proof
    ) external {
      if (_root == 0) {
        _root = ORACLE.commitment().root;
      }

      // TODO: update this potentially
      bool valid = ORACLE.verify({
        _nullifierHash: _nullifierHash,
        _signal: _signal,
        _externalNullifier: _externalNullifier,
        _proof: _proof
      });

      if (!valid) revert InvalidProof();
      residents[msg.sender] = true;
    }

    /// @notice
    function winners() external view returns (address[] memory) {
      bytes32 seed = random;

      address[] memory _winners = new address[](10);
      for (uint256 i = 0; i < 10; i++) {
        seed = keccak256(abi.encode(seed));
        uint256 index = uint256(seed) % totalSupply;
        address winner = ownerOf(index);
        _winners[i] = winner;
      }

      return _winners;
    }

    /// @notice
    function safeMint(address _to) onlyResident external payable {
      if (block.timestamp > END) revert Ended();

      if (msg.value != 0.1 ether) revert InvalidAmount();

      _safeMint(_to, totalSupply);

      random = keccak256(abi.encode(random, block.timestamp));
      totalSupply++;
    }

    function approve(address, uint256) public pure override {
        revert SoulBound();
    }

    function setApprovalForAll(address, bool) public virtual override {
        revert SoulBound();
    }

    function transferFrom(address, address, uint256) public pure override {
        revert SoulBound();
    }

    function transfer(address, uint256) public pure {
        revert SoulBound();
    }

    /// @notice TODO: rename this
    function transfer() external {
      (bool success, ) = RECIPIENT.call{ value: address(this).balance }("");
      if (!success) revert TransferFailed();
    }

    /// @notice
    function tokenURI(uint256 _id) public pure override returns (string memory) {
      return "";
    }
}
