// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INft} from "./interfaces/INft.sol";

contract Nft is
    INft,
    Initializable,
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
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

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */
    mapping(uint256 => Band) internal s_bands; // token ID => band
    mapping(uint16 => uint256) internal s_levelToPrice; // level => price in USD
    uint256 internal s_nextTokenId;
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
        string memory name,
        string memory symbol,
        IERC20 tokenUSDT,
        IERC20 tokenUSDC
    )
        external
        initializer
        mAddressNotZero(address(tokenUSDT))
        mAddressNotZero(address(tokenUSDC))
    {
        __ERC721_init(name, symbol);
        __ERC721Burnable_init();
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

        // Effects: Increment the token ID
        // The tokenId is set to the current s_nextTokenId (pre-increment)
        uint256 tokenId = s_nextTokenId++;

        // Effects: mint the band
        _safeMint(msg.sender, tokenId);

        // Effects: set the band data
        s_bands[tokenId] = Band({level: level, isGenesis: false});

        emit BandMinted(msg.sender, tokenId, level, false);
    }

    function updateBand(
        uint256 tokenId,
        uint16 newLevel,
        IERC20 token
    ) external mValidBandLevel(newLevel) mTokenExists(token) {
        // Checks: the sender must be the owner of the band
        if (ownerOf(tokenId) != msg.sender) {
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

            // Effects: Increment the token ID
            // The newTokenId is set to the current s_nextTokenId (pre-increment)
            uint256 newTokenId = s_nextTokenId++;

            // Effects: burn previously owned band
            _burn(tokenId);

            // Effects: purchase new band
            _purchaseBand(token, upgradeCost);

            // Effects: mint the band
            _safeMint(msg.sender, newTokenId);
        }
        // newLevel < currentLevel
        else {
            uint256 downgradeRefund = s_levelToPrice[currentLevel] -
                s_levelToPrice[newLevel];

            // Effects: Increment the token ID
            // The newTokenId is set to the current s_nextTokenId (pre-increment)
            uint256 newTokenId = s_nextTokenId++;

            // Effects: burn previously owned band
            _burn(tokenId);

            // Effects: refund the user
            _refundBandDowngrade(token, downgradeRefund);

            // Effects: mint the band
            _safeMint(msg.sender, newTokenId);
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
            // Effects: Increment the token ID
            // The tokenId is set to the current s_nextTokenId (pre-increment)
            uint256 tokenId = s_nextTokenId++;

            // Effects: mint genesis band
            _safeMint(receiver, tokenId);

            // Effects: set the band data
            s_bands[tokenId] = Band({level: level, isGenesis: true});

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
        return s_nextTokenId;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                OVERRIDE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    // The following functions are overrides required by Solidity.

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
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
}
