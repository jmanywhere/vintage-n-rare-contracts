// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC721} from "openzeppelin/token/ERC721/ERC721.sol";
import {IERC721Receiver} from "openzeppelin/token/ERC721/IERC721Receiver.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";

error Unauthorized();
error VnR__TransferFailedETH();
error VnR__HashAlreadyExists();
error VnR__NotTheOwner();
error VnR__InvalidTokenId();
error VnR__NoZeroAddress();
error VnR__OnlyWhileMinting();
error VnR__NoBalance();
error VnR__InvalidURI();

/**
 * @title VintageAndRareNFTs
 * @dev ERC721 contract for Vintage and Rare NFTs
 * Vintage and Rare is a collection of NFTs that represent Collection Watches. Each watch is minted with a unique ID and has a unique set of attributes.
 * The attributes are:
 * 1. Name
 * 2. Brand
 * 3. Model
 * 4. Year
 * 5. Finish
 * 6. Serial Number
 * Attributes and Img are stored in IPFS and the hash for the JSON is stored in the contract.
 */

contract VintageAndRareNFTs is
    ERC721,
    Ownable,
    IERC721Receiver,
    ReentrancyGuard
{
    //-------------------------------------------------------------------------
    // STATE Variables
    //-------------------------------------------------------------------------
    uint256 public totalSupply;

    mapping(address => bool) public creators;
    mapping(uint256 => string) private _tokenURI;
    mapping(uint256 => address) public tokenCreator;
    mapping(bytes32 => uint) private ipfsToID;
    mapping(uint => address) public mintOwner;

    string public contractURI = "";
    uint public publicFee;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------
    event SetPublicFee(uint indexed prevFee, uint indexed newFee);
    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------
    modifier checkCreator() {
        bool isCreator = creators[msg.sender];
        bool hasValue = msg.value >= publicFee;
        if (isCreator || publicFee == 0 || hasValue) _;
        else {
            revert Unauthorized();
        }
    }

    //----------------------------------------------------- --------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        totalSupply = 0;
        creators[msg.sender] = true;
        publicFee = 0.15 ether;
    }

    //-------------------------------------------------------------------------
    // EXTERNAL / PUBLIC FUNCTIONS
    //-------------------------------------------------------------------------

    /**
     * @notice Mints the NFT and stores the IPFS URI in the contract
     * @param _uri - IPFS URI for the JSON metadata
     * @return _id - ID of the NFT
     */
    function mint(
        string memory _uri
    ) public payable checkCreator nonReentrant returns (uint256) {
        if (msg.value > 0) {
            (bool succ, ) = owner().call{value: msg.value}("");
            if (!succ) revert VnR__TransferFailedETH();
        }
        totalSupply++;
        uint256 _id = totalSupply;
        bytes32 hashedURI = cidToBytes32(_uri);
        if (ipfsToID[hashedURI] != 0) revert VnR__HashAlreadyExists();

        _tokenURI[_id] = _uri;
        ipfsToID[hashedURI] = _id;
        tokenCreator[_id] = msg.sender;
        _safeMint(address(this), _id);
        return _id;
    }

    /**
     * @notice Transfers ownership of the NFT to the respective owner
     * @param _id - ID of the NFT to claim
     */
    function claimMintedToken(uint256 _id) public nonReentrant {
        if (mintOwner[_id] != msg.sender || mintOwner[_id] == address(0))
            revert VnR__NotTheOwner();
        mintOwner[_id] = address(0);
        _safeTransfer(address(this), msg.sender, _id, "");
    }

    /**
     * @notice Sets the fee to be paid the creator of the NFT if they're not an approved creator
     * @param _fee - fee to be paid by the public
     */
    function setPublicFee(uint _fee) public onlyOwner {
        emit SetPublicFee(publicFee, _fee);
        publicFee = _fee;
    }

    /**
     * @notice implements the ERC721Receiver interface to take action if any NFTs are received
     * @param operator address to check if it can receive the NFT
     * @param from address from which the NFT is being transferred
     * @param tokenId id of the NFT to transfer
     *
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        if (from != address(0)) revert VnR__OnlyWhileMinting();
        mintOwner[tokenId] = operator;
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice sets the contract's URI Metadata for the collection
     * @param _uri - URI to set for the contract
     */
    function setContractURI(string memory _uri) public onlyOwner {
        if (bytes(_uri).length == 0 || bytes(contractURI).length != 0)
            revert VnR__InvalidURI();

        contractURI = _uri;
    }

    /**
     * @notice Sets a specific address to set as a fee free creator
     * @param _creator Address that is allowed to mint NFTs for free
     * @param _value Sets whether the creator is allowed to mint NFTs for free
     */
    function setCreator(address _creator, bool _value) public onlyOwner {
        creators[_creator] = _value;
    }

    /**
     * @notice withdraws the fees from the contract to owner directly
     */
    function getFees() external onlyOwner {
        uint balance = address(this).balance;
        if (balance == 0) revert VnR__NoBalance();
        (bool succ, ) = msg.sender.call{value: balance}("");
        if (!succ) revert VnR__TransferFailedETH();
    }

    //-------------------------------------------------------------------------
    // EXTERNAL / PUBLIC VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    /**
     * @notice returns the address of the owner of the NFT
     * @param tokenId - ID of the NFT
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _ownerOf(tokenId);
        if (mintOwner[tokenId] != address(0)) {
            owner = mintOwner[tokenId];
        }
        if (owner == address(0)) revert VnR__InvalidTokenId();
        return owner;
    }

    /**
     * @notice returns the URI for a given NFTs ID
     * @param _tokenId - ID of the NFT
     * @return _uri - IPFS URI for the JSON metadata
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), _tokenURI[_tokenId]));
    }

    /**
     * @notice checks if the the CID is used already
     * @param cid - IPFS URI for the JSON metadata
     * @return bool - true if the CID is used already
     */
    function isValidCid(string memory cid) public view returns (bool) {
        bytes32 hash = cidToBytes32(cid);
        return ipfsToID[hash] > 0;
    }

    //-------------------------------------------------------------------------
    // INTERNAL PURE FUNCTIONS
    //-------------------------------------------------------------------------
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function cidToBytes32(string memory cid) private pure returns (bytes32) {
        bytes32 result;
        assembly {
            result := mload(add(cid, 32))
        }
        return result;
    }
}
