// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { ERC721 } from "solmate/tokens/ERC721.sol";
import { ZuzaluOracle } from "./ZuzaluOracle.sol";

/// @notice A lottery contract to raise money for Zuzalu.
///         Participants must register their ethereum account
///         with a semaphore proof to add themselves to the
///         allowlist so that they can mint the NFT. The NFTs
///         are soulbound meaning that they cannot be transferred.
contract Lottery is ERC721 {
    /// @notice An error for when a non resident attempts to mint.
    error NotResident(address);

    /// @notice An error for when there is an invalid proof.
    error InvalidProof();

    /// @notice An error for when the user uses the wrong amount of ether
    ///         to mint.
    error InvalidAmount();

    /// @notice An error for when the user attempts to mint after the
    ///         minting period has ended.
    error Ended();

    /// @notice An error for when the claim transfer fails.
    error TransferFailed();

    /// @notice An error for when users attempt to transfer the NFT.
    error SoulBound();

    /// @notice The address of the oracle contract.
    ZuzaluOracle immutable public ORACLE;

    /// @notice The timestamp of the end of minting
    uint256 immutable public END;

    /// @notice The recipient of any funds the contract accumulates.
    address immutable public RECIPIENT;

    /// @notice The price for minting an NFT
    uint256 constant public MINT_PRICE = 0.1 ether;

    /// @notice The number of winners
    uint256 constant public WINNER_COUNT = 10;

    /// @notice The randomness used to compute the winners of the
    ///         lottery.
    bytes32 public random;

    /// @notice The total supply of NFTs.
    uint256 public totalSupply;

    /// @notice After a resident proves that they are part of Zuzalu
    ///         using semaphore, they are added to this mapping.
    mapping(address => bool) public residents;

    /// @notice Creates the lottery contract and initializes the
    ///         randomness.
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

    /// @notice Ensures that only a resident can call the function.
    modifier onlyResident() {
      if (!residents[msg.sender]) revert NotResident(msg.sender);
      _;
    }

    /// @notice A valid proof will add the user to the allowlist.
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

      bool valid = ORACLE.verify({
        _nullifierHash: _nullifierHash,
        _signal: _signal,
        _externalNullifier: _externalNullifier,
        _proof: _proof
      });

      if (!valid) revert InvalidProof();
      residents[msg.sender] = true;
    }

    /// @notice Compute the winners of the lottery. This function
    ///         can be called at anytime to see the current winners.
    /// @dev    This should only be called during simulation.
    function winners() external view returns (address[] memory) {
      bytes32 seed = random;

      address[] memory _winners = new address[](WINNER_COUNT);
      for (uint256 i = 0; i < WINNER_COUNT; i++) {
        seed = keccak256(abi.encode(seed));
        uint256 index = uint256(seed) % totalSupply;
        address winner = ownerOf(index);
        _winners[i] = winner;
      }

      return _winners;
    }

    /// @notice Users can mint. The exact value must be sent and
    ///         the randomness is updated.
    function safeMint(address _to) onlyResident external payable {
      if (block.timestamp >= END) revert Ended();

      if (msg.value != MINT_PRICE) revert InvalidAmount();

      _safeMint(_to, totalSupply);

      random = keccak256(abi.encode(random, block.timestamp));
      totalSupply++;
    }

    /// @notice Soulbound tokens cannot be transferred.
    function approve(address, uint256) public pure override {
        revert SoulBound();
    }

    /// @notice Soulbound tokens cannot be transferred.
    function setApprovalForAll(address, bool) public virtual override {
        revert SoulBound();
    }

    /// @notice Soulbound tokens cannot be transferred.
    function transferFrom(address, address, uint256) public pure override {
        revert SoulBound();
    }

    /// @notice Soulbound tokens cannot be transferred.
    function transfer(address, uint256) public pure {
        revert SoulBound();
    }

    /// @notice Send any funds in the contract to a hardcoded account
    ///         that is defined at deploy time.
    function claim() external {
      (bool success, ) = RECIPIENT.call{ value: address(this).balance }("");
      if (!success) revert TransferFailed();
    }

    /// @notice The URI for the NFT metadata.
    function tokenURI(uint256 _id) public pure override returns (string memory) {
      return "";
    }

    /// @notice A function useful for backrunning the end of the
    ///         NFT sale. Users must send ether to have the right
    ///         to bias the function.
    function bias(bytes32 _random) external payable {
      if (msg.value != 0.1 ether) revert InvalidAmount();
      random = keccak256(abi.encode(random, _random));
    }
}
