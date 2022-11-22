// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
//import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Utopia is Ownable, ERC721A, ReentrancyGuard {

    mapping(address => bool) public allowedToMint;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) ERC721A("Utopia", "UTOPIA", maxBatchSize_, collectionSize_) {

    }

    modifier onlyMintAllowedUsers() {
        require(allowedToMint[msg.sender], "You can't mint ;)");
        _;
    }

    function setAddresToMintAllowed(address _account, bool _canMint) public onlyOwner {
        allowedToMint[_account] = _canMint;
    }

    function mint(address to, uint256 qty) onlyMintAllowedUsers external {
        _safeMint(to, qty);
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalNFTs = totalSupply();
            uint256 i = 0;

            uint256 tId;

            for (tId = 1; tId <= totalNFTs; ++tId) {
                if (ownerOf(tId) == _owner) {
                    result[i] = tId;
                    ++i;
                }
            }

            return result;
        }
    }

    function feeDenominator() external virtual returns (uint96) {
        return _feeDenominator();
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) internal onlyOwner {
        _resetTokenRoyalty(tokenId);
    }
}