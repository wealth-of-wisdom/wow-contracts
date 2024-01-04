// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INft} from "./interfaces/INft.sol";
import {Nft} from "./Nft.sol";

contract NftSale is
    INft,
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    /*//////////////////////////////////////////////////////////////////////////
                                    LIBRARIES
    //////////////////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal s_tokenUSDT;
    IERC20 internal s_tokenUSDC;
    Nft internal s_contractNFT;

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */
    mapping(uint256 => Band) internal s_bands; // token ID => band
    mapping(uint16 => uint256) internal s_levelToPrice; // level => price in USD
    uint16 internal s_maxLevel;
    /* solhint-enable */

    /*//////////////////////////////////////////////////////////////////////////
                                  MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier mAddressNotZero(address addr) {
        if (addr == address(0)) {
            revert Nft__ZeroAddress();
        }
        _;
    }

    modifier mTokenExists(IERC20 token) {
        if (token != s_tokenUSDT && token != s_tokenUSDC) {
            revert Nft__NonExistantPayment();
        }
        _;
    }

    modifier mAmountNotZero(uint256 amount) {
        if (amount == 0) {
            revert Nft__PassedZeroAmount();
        }
        _;
    }

    modifier mValidBandLevel(uint16 level) {
        if (level == 0 || level > s_maxLevel) {
            revert Nft__InvalidLevel(level);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        IERC20 tokenUSDT,
        IERC20 tokenUSDC,
        Nft contractNFT
    )
        external
        initializer
        mAddressNotZero(address(tokenUSDT))
        mAddressNotZero(address(tokenUSDC))
    {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        s_maxLevel = 5;
        s_levelToPrice[1] = 1_000 * 10 ** 6;
        s_levelToPrice[2] = 5_000 * 10 ** 6;
        s_levelToPrice[3] = 10_000 * 10 ** 6;
        s_levelToPrice[4] = 33_000 * 10 ** 6;
        s_levelToPrice[5] = 100_000 * 10 ** 6;

        s_tokenUSDT = tokenUSDT;
        s_tokenUSDC = tokenUSDC;
        s_contractNFT = contractNFT;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS FOR USERS
    //////////////////////////////////////////////////////////////////////////*/

    function mintBand(
        uint16 level,
        IERC20 token
    ) external mValidBandLevel(level) mTokenExists(token) {
        uint256 cost = s_levelToPrice[level];

        // Effects: Transfer the payment to the contract
        _purchaseBand(token, cost);

        // Effects: mint the band
        s_contractNFT.safeMint(msg.sender);

        // Effects: set the band data
        uint256 tokenId = s_contractNFT._nextTokenId();
        s_bands[tokenId] = Band({
            level: level,
            isGenesis: false,
            isActive: true
        });
        emit BandMinted(msg.sender, tokenId, level, false);
    }

    function updateBand(
        uint256 tokenId,
        uint16 newLevel,
        IERC20 token
    ) external mValidBandLevel(newLevel) mTokenExists(token) {
        // Checks: the sender must be the owner of the band
        if (s_contractNFT.ownerOf(tokenId) != msg.sender) {
            revert Nft__NotBandOwner();
        }

        Band storage band = s_bands[tokenId];
        uint16 currentLevel = band.level;

        // Checks: the new level must be different from the current level
        if (newLevel == currentLevel) {
            revert Nft__InvalidLevel(newLevel);
        }

        // Effects: Update the band level
        band.level = newLevel;

        if (newLevel > currentLevel) {
            uint256 upgradeCost = s_levelToPrice[newLevel] -
                s_levelToPrice[currentLevel];
            _purchaseBand(token, upgradeCost);
            _updateBand(tokenId, currentLevel, newLevel);
        }
        // newLevel < currentLevel
        else {
            uint256 downgradeRefund = s_levelToPrice[currentLevel] -
                s_levelToPrice[newLevel];

            _refundBandDowngrade(token, downgradeRefund);
            _updateBand(tokenId, currentLevel, newLevel);
        }

        emit BandUpdated(msg.sender, tokenId, currentLevel, newLevel);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR ADMIN ROLE
    //////////////////////////////////////////////////////////////////////////*/

    function withdrawTokens(
        IERC20 token,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAmountNotZero(amount) {
        uint256 balance = token.balanceOf(address(this));

        // Checks: the contract must have enough balance to withdraw
        if (balance < amount) {
            revert Nft__InsufficientContractBalance(balance, amount);
        }

        // Interaction: transfer the tokens to the sender
        token.safeTransfer(msg.sender, amount);

        emit TokensWithdrawn(token, msg.sender, amount);
    }

    function setMaxLevel(
        uint16 maxLevel
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: the new max level must be greater than the current max level
        if (maxLevel <= s_maxLevel) {
            revert Nft__InvalidMaxLevel(maxLevel);
        }

        // Effects: set the new max level
        s_maxLevel = maxLevel;

        emit MaxLevelSet(maxLevel);
    }

    function setLevelPrice(
        uint16 level,
        uint256 price
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mValidBandLevel(level)
        mAmountNotZero(price)
    {
        s_levelToPrice[level] = price;

        emit LevelPriceSet(level, price);
    }

    function mintGenesisBand(
        address receiver,
        uint16 level,
        uint16 amount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAddressNotZero(receiver)
        mValidBandLevel(level)
        mAmountNotZero(amount)
    {
        for (uint256 i = 0; i < amount; i++) {
            // Effects: mint genesis band
            s_contractNFT.safeMint(msg.sender);

            uint256 tokenId = s_contractNFT._nextTokenId();
            // Effects: set the band data
            s_bands[tokenId] = Band({
                level: level,
                isGenesis: true,
                isActive: true
            });
            emit BandMinted(receiver, tokenId, level, true);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getTokenUSDT() external view returns (IERC20) {
        return s_tokenUSDT;
    }

    function getTokenUSDC() external view returns (IERC20) {
        return s_tokenUSDC;
    }

    function getBand(uint256 tokenId) external view returns (Band memory) {
        return s_bands[tokenId];
    }

    function getLevelPriceInUSD(uint16 level) external view returns (uint256) {
        return s_levelToPrice[level];
    }

    function getMaxLevel() external view returns (uint16) {
        return s_maxLevel;
    }

    function getNextTokenId() external view returns (uint256) {
        return s_contractNFT._nextTokenId();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                OVERRIDE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    // The following functions are overrides required by Solidity.

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR UPGRADER ROLE
    //////////////////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {
        /// @dev This function is empty but uses a modifier to restrict access
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _purchaseBand(
        IERC20 token,
        uint256 cost
    ) internal virtual mTokenExists(token) {
        // Interaction: transfer the payment to the contract
        token.safeTransferFrom(msg.sender, address(this), cost);

        emit PurchasePaid(token, cost);
    }

    function _refundBandDowngrade(
        IERC20 token,
        uint256 cost
    ) internal virtual mTokenExists(token) {
        uint256 balance = token.balanceOf(address(this));

        // Checks: the contract must have enough balance to refund
        if (balance < cost) {
            revert Nft__InsufficientContractBalance(balance, cost);
        }

        // Interaction: transfer the refund to the user
        token.safeTransfer(msg.sender, cost);

        emit RefundPaid(token, cost);
    }

    function _updateBand(
        uint256 tokenId,
        uint16 currentLevel,
        uint16 newLevel
    ) internal virtual {
        s_bands[tokenId] = Band({
            level: currentLevel,
            isGenesis: false,
            isActive: false
        });

        //@todo think about multiple minting processes at the same time
        // will it affect id catching
        s_contractNFT.safeMint(msg.sender);

        uint256 newTokenId = s_contractNFT._nextTokenId();
        s_bands[newTokenId] = Band({
            level: newLevel,
            isGenesis: false,
            isActive: true
        });
    }
}
