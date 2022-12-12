// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract Utopia is Ownable, ERC721A, ReentrancyGuard {

    using Strings for uint256;

    mapping(address => bool) public allowedToMint;

    bool public isRevealed = false;
    bool public mintFinished = false;

    string private _baseTokenURI = "";
    string private _unrevealedTokenURI = "";
    string private _baseTokenEndURI = "";

    event SetRevealed(bool indexed _isRevealed);
    event SetMintFinished(bool indexed _mintFinished);
    event SetAddressToMintAllowed(address indexed _account, bool indexed _canMint);
    event SetBaseURI(string indexed _baseURI);
    event SetUnrevealedURI(string indexed _unrevealedURI);
    event SetEndURI(string indexed _endURI);
    event SetOwnersExplicit(uint256 indexed _quantity);
    event SetDefaultRoyalty(address indexed _receiver, uint96 indexed _feeNumerator);
    event SetTokenRoyalty(uint256 indexed _tokenId, address indexed _receiver, uint96 indexed _feeNumerator);
    event ResetTokenRoyalty(uint256 indexed _tokenId);

    modifier onlyMintAllowedUsers() {
        require(allowedToMint[msg.sender], "You can't mint ;)");
        _;
    }

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) ERC721A("Utopia", "UTOPIA", maxBatchSize_, collectionSize_) {

    }

    function setRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
        emit SetRevealed(_isRevealed);
    }

    function setMintFinished(bool _mintFinished) external onlyOwner {
        mintFinished = _mintFinished;
        emit SetMintFinished(_mintFinished);
    }

    function setAddressToMintAllowed(address _account, bool _canMint) external onlyOwner {
        allowedToMint[_account] = _canMint;
        emit SetAddressToMintAllowed(_account, _canMint);
    }

    function mint(address to, uint256 qty) onlyMintAllowedUsers nonReentrant external {
        _safeMint(to, qty);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        require(mintFinished, "Utopia: minting must be completed first");
        _baseTokenURI = baseURI;
        emit SetBaseURI(baseURI);
    }

    function setUnrevealedURI(string calldata unrevealedURI) external onlyOwner {
        _unrevealedTokenURI = unrevealedURI;
        emit SetUnrevealedURI(unrevealedURI);
    }

    function setEndURI(string calldata endURI) external onlyOwner {
        _baseTokenEndURI = endURI;
        emit SetEndURI(endURI);
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner {
        _setOwnersExplicit(quantity);
        emit SetOwnersExplicit(quantity);
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
    */
    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        string memory unrevealedURI = _unrevealedURI();
        string memory endURI = _endURI();

        if (bytes(baseURI).length == 0) {
            return "";
        }

        if (isRevealed) {
            return string(abi.encodePacked(baseURI, tokenId.toString(), endURI));
        } else {
            return string(abi.encodePacked(unrevealedURI, "0", endURI));
        }
    }

    function feeDenominator() external virtual returns (uint96) {
        return _feeDenominator();
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit SetDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
        emit SetTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
        emit ResetTokenRoyalty(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _unrevealedURI() internal view virtual returns (string memory) {
        return _unrevealedTokenURI;
    }

    function _endURI() internal view virtual override returns (string memory) {
        return _baseTokenEndURI;
    }
}