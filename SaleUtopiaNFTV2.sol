// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IERC721Receiver.sol";
import "./MerkleProof.sol";

interface IUtopia {
    function mint(address to, uint256 qty) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract SaleUtopiaNFTV2 is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;

    // treasuryAddr
    address public treasuryAddr;
    // Utopia SC collection
    IUtopia public immutable utopia;
    // Price Feed
    AggregatorV3Interface internal priceFeed;
    // Current Phase
    uint8 public currentPhaseId;
    // Info of each phase.
    struct PhaseInfo {
        uint256 priceInUSDPerNFT;
        uint256 priceInUSDPerNFTWithoutWhiteList;
        uint256 maxTotalSales;
        uint256 maxSalesPerWallet;
        bool whiteListRequired;
        bool phasePriceInUSD;
        uint256 priceInWeiPerNFT;
        uint256 priceInWeiPerNFTWithoutWhiteList;
    }
    // Phases Info
    PhaseInfo[] public phasesInfo;
    // Phases Total Sales
    mapping(uint256 => uint256) public phasesTotalSales;
    // Phases Wallet Sales
    mapping(uint256 => mapping(address => uint256)) public phasesWalletSales;
    // AllowList
    bytes32 public allowlistMerkleRoot;

    event AddPhase(uint256 indexed _priceInUSDPerNFT, uint256 indexed _priceInUSDPerNFTWithoutWhiteList, uint256 _maxTotalSales, uint256 _maxSalesPerWallet, bool _whiteListRequired, bool _phasePriceInUSD, uint256 _priceInWeiPerNFT, uint256 _priceInWeiPerNFTWithoutWhiteList);
    event EditPhase(uint8 indexed _phaseId, uint256 indexed _priceInUSDPerNFT, uint256 _priceInUSDPerNFTWithoutWhiteList, uint256 _maxTotalSales, uint256 _maxSalesPerWallet, bool _whiteListRequired, bool _phasePriceInUSD, uint256 _priceInWeiPerNFT, uint256 _priceInWeiPerNFTWithoutWhiteList);
    event ChangeCurrentPhase(uint8 indexed _phaseId);
    event ChangePriceFeedAddress(address indexed _priceFeedAddress);
    event Buy(uint256 indexed quantity, address indexed to);
    event BuyWithCreditCard(uint256 indexed quantity, address indexed to);

    constructor(
        IUtopia _utopia,
        address _treasuryAddr,
        address _priceFeedAddress,
        uint8 _currentPhaseId
    ) {
        utopia = _utopia;
        treasuryAddr = _treasuryAddr;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        currentPhaseId = _currentPhaseId;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    modifier onlyAllowListed(bytes32[] calldata _merkleProof) {
        PhaseInfo storage phase = phasesInfo[currentPhaseId];

        if (phase.whiteListRequired) {
            bool passMerkle = _checkMerkleProof(_merkleProof);
            require(passMerkle, "Not allowListed");
        }
        _;
    }

    function _checkMerkleProof(bytes32[] calldata _merkleProof) internal virtual returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf);
    }

    function setCurrentPhase(uint8 _currentPhaseId) external onlyOwner {
        currentPhaseId = _currentPhaseId;
        emit ChangeCurrentPhase(_currentPhaseId);
    }

    function changePriceFeedAddress(address _priceFeedAddress) external onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        emit ChangePriceFeedAddress(_priceFeedAddress);
    }

    function addPhase(uint256 _priceInUSDPerNFT, uint256 _priceInUSDPerNFTWithoutWhiteList, uint256 _maxTotalSales, uint256 _maxSalesPerWallet, bool _whiteListRequired, bool _phasePriceInUSD, uint256 _priceInWeiPerNFT, uint256 _priceInWeiPerNFTWithoutWhiteList) external onlyOwner {
        phasesInfo.push(PhaseInfo({
            priceInUSDPerNFT: _priceInUSDPerNFT,
            priceInUSDPerNFTWithoutWhiteList: _priceInUSDPerNFTWithoutWhiteList,
            maxTotalSales: _maxTotalSales,
            maxSalesPerWallet: _maxSalesPerWallet,
            whiteListRequired: _whiteListRequired,
            phasePriceInUSD: _phasePriceInUSD,
            priceInWeiPerNFT: _priceInWeiPerNFT,
            priceInWeiPerNFTWithoutWhiteList: _priceInWeiPerNFTWithoutWhiteList
        }));

        emit AddPhase(_priceInUSDPerNFT, _priceInUSDPerNFTWithoutWhiteList, _maxTotalSales, _maxSalesPerWallet, _whiteListRequired, _phasePriceInUSD, _priceInWeiPerNFT, _priceInWeiPerNFTWithoutWhiteList);
    }

    function editPhase(uint8 _phaseId, uint256 _priceInUSDPerNFT, uint256 _priceInUSDPerNFTWithoutWhiteList, uint256 _maxTotalSales, uint256 _maxSalesPerWallet, bool _whiteListRequired, bool _phasePriceInUSD, uint256 _priceInWeiPerNFT, uint256 _priceInWeiPerNFTWithoutWhiteList) external onlyOwner {
        phasesInfo[_phaseId].priceInUSDPerNFT = _priceInUSDPerNFT;
        phasesInfo[_phaseId].priceInUSDPerNFTWithoutWhiteList = _priceInUSDPerNFTWithoutWhiteList;
        phasesInfo[_phaseId].maxTotalSales = _maxTotalSales;
        phasesInfo[_phaseId].maxSalesPerWallet = _maxSalesPerWallet;
        phasesInfo[_phaseId].whiteListRequired = _whiteListRequired;
        phasesInfo[_phaseId].phasePriceInUSD = _phasePriceInUSD;
        phasesInfo[_phaseId].priceInWeiPerNFT = _priceInWeiPerNFT;
        phasesInfo[_phaseId].priceInWeiPerNFTWithoutWhiteList = _priceInWeiPerNFTWithoutWhiteList;

        emit EditPhase(_phaseId, _priceInUSDPerNFT, _priceInUSDPerNFTWithoutWhiteList, _maxTotalSales, _maxSalesPerWallet, _whiteListRequired, _phasePriceInUSD, _priceInWeiPerNFT, _priceInWeiPerNFTWithoutWhiteList);
    }

    function getLatestPrice() public view returns (int) {
        (
            ,
            int price,
            ,
            ,

        ) = priceFeed.latestRoundData();

        return (
            price
        );
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot) external onlyOwner {
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    function buyWithCreditCard(uint256 _quantity, address _to, bytes32[] calldata _merkleProof) external onlyOwner nonReentrant {
        _buy(_quantity, _to, true, _merkleProof);
        emit BuyWithCreditCard(_quantity, _to);
    }

    function buy(uint256 _quantity, address _to, bytes32[] calldata _merkleProof) external payable nonReentrant onlyAllowListed(_merkleProof) {
        _buy(_quantity, _to, false, _merkleProof);
        emit Buy(_quantity, _to);
    }

    function _buy(uint256 _quantity, address _to, bool _isCreditCardPayment, bytes32[] calldata _merkleProof) internal {
        uint256 totalPrice = 0;
        uint256 priceInUSD = 0;
        uint256 priceInWei = 0;

        PhaseInfo storage phase = phasesInfo[currentPhaseId];

        require(phase.maxTotalSales >= phasesTotalSales[currentPhaseId].add(_quantity), "this phase does not allow this purchase");

        if (!_isCreditCardPayment) {
            require(phase.maxSalesPerWallet >= phasesWalletSales[currentPhaseId][_to].add(_quantity), "you can not buy as many NFTs in this phase");
        }

        priceInUSD = phase.priceInUSDPerNFTWithoutWhiteList;
        priceInWei = phase.priceInWeiPerNFTWithoutWhiteList;

        if (!_isCreditCardPayment) {
            if (_checkMerkleProof(_merkleProof)) {
                priceInUSD = phase.priceInUSDPerNFT;
                priceInWei = phase.priceInWeiPerNFT;
            }
        }

        if (phase.phasePriceInUSD) {
            uint256 totalPriceInUSD = priceInUSD.mul(_quantity).mul(1e8).mul(1e18);

            (
            int ethPrice
            ) = getLatestPrice();

            uint256 ethPrice256 = uint256(ethPrice);
            totalPrice = totalPriceInUSD.div(ethPrice256);
        } else {
            totalPrice = priceInWei.mul(_quantity);
        }

        if (_isCreditCardPayment) {
            totalPrice = 0;
        }

        phasesTotalSales[currentPhaseId] = phasesTotalSales[currentPhaseId].add(_quantity);
        phasesWalletSales[currentPhaseId][_to] = phasesWalletSales[currentPhaseId][_to].add(_quantity);

        refundIfOver(totalPrice);
        treasuryAddr.call{value: address(this).balance}("");
        utopia.mint(_to, _quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setTreasury(address _treasuryAddr) external onlyOwner {
        treasuryAddr = _treasuryAddr;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = treasuryAddr.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function transferGuardedNfts(uint256[] memory tokensId, address[] memory addresses) external onlyOwner
    {
        require(
            addresses.length == tokensId.length,
            "addresses does not match tokensId length"
        );

        for (uint256 i = 0; i < addresses.length; ++i) {
            utopia.safeTransferFrom(address(this), addresses[i], tokensId[i]);
        }
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function recoverERC721TransferFrom(address nftAddress, address from, address to, uint256 tokenId) external virtual onlyOwner {
        IERC721(nftAddress).transferFrom(from, to, tokenId);
    }

    function recoverERC721SafeTransferFrom(address nftAddress, address from, address to, uint256 tokenId) external virtual onlyOwner {
        IERC721(nftAddress).safeTransferFrom(from, to, tokenId);
    }

}