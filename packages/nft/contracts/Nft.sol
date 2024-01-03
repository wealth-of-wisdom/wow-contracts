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
    using SafeERC20 for IERC20;
    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 public USDTtokenAddress;
    IERC20 public USDCtokenAddress;

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */
    mapping(uint256 => Band) internal s_bands; // token ID => band
    mapping(uint16 => uint256) internal s_level_pricing; // level => price in USD
    uint256 internal s_nextTokenId;
    uint16 internal s_maxLevel;
    /* solhint-enable */

    /*//////////////////////////////////////////////////////////////////////////
                                  MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier mAddressNotZero(address addr) {
        if (addr == address(0)) revert Nft__ZeroAddress();
        _;
    }

    modifier mTokenExists(IERC20 tokenAddress) {
        if (
            tokenAddress != USDTtokenAddress || tokenAddress != USDCtokenAddress
        ) {
            revert Nft__NonExistantPayment();
        }
        _;
    }

    modifier mAmountNotZero(uint256 amount) {
        if (amount == 0) revert Nft__PassedZeroAmount();
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
        IERC20 USDTaddress,
        IERC20 USDCaddress
    )
        public
        initializer
        mAddressNotZero(address(USDTaddress))
        mAddressNotZero(address(USDCaddress))
    {
        __ERC721_init(name, symbol);
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        s_maxLevel = 5;
        s_level_pricing[1] = 1_000;
        s_level_pricing[2] = 5_000;
        s_level_pricing[3] = 10_000;
        s_level_pricing[4] = 33_000;
        s_level_pricing[5] = 100_000;

        USDTtokenAddress = USDTaddress;
        USDCtokenAddress = USDCaddress;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS FOR USERS
    //////////////////////////////////////////////////////////////////////////*/

    function mintBand(uint16 level, IERC20 assetAddress) external {
        // Checks: level must be valid
        if (level > s_maxLevel) {
            revert Nft__InvalidLevel(level);
        }

        uint256 cost = getBandLevelCost(level);
        _purchaseBand(assetAddress, cost);

        // Effects: mint the band
        uint256 tokenId = ++s_nextTokenId;
        _safeMint(msg.sender, tokenId);

        // Effects: set the band data
        s_bands[tokenId] = Band({level: level, isGenesis: false});

        emit BandMinted(msg.sender, tokenId, level, false);
    }

    function changeBand(
        uint256 tokenId,
        uint16 newLevel,
        IERC20 assetAddress
    ) external {
        if (ownerOf(tokenId) != msg.sender) {
            revert Nft__NotBandOwner();
        }

        Band storage band = s_bands[tokenId];
        uint16 currentLevel = band.level;

        if (newLevel > s_maxLevel || newLevel == currentLevel) {
            revert Nft__InvalidLevel(newLevel);
        }

        if (newLevel > currentLevel) {
            uint256 upgradeCost = getBandLevelCost(newLevel) -
                getBandLevelCost(currentLevel);
            // Effects: burn previously owned band
            _burn(tokenId);
            // Effects: purchase new band
            _purchaseBand(assetAddress, upgradeCost);
            // Effects: mint the band
            tokenId = ++s_nextTokenId;
            _safeMint(msg.sender, tokenId);
        }
        // newLevel < currentLevel
        else {
            uint256 downgradeRefund = getBandLevelCost(currentLevel) -
                getBandLevelCost(newLevel);

            if (address(this).balance < downgradeRefund) {
                revert Nft__InsufficientContractBalance(
                    address(this).balance,
                    downgradeRefund
                );
            }

            // Refund the excess payment
            if (downgradeRefund > 0) {
                // Effects: burn previously owned band
                _burn(tokenId);
                _refundBandDowngrade(assetAddress, downgradeRefund);
                // Effects: mint the band
                tokenId = ++s_nextTokenId;
                _safeMint(msg.sender, tokenId);
            }
        }

        band.level = newLevel;

        emit BandChanged(msg.sender, tokenId, currentLevel, newLevel);
    }

    function withdrawTokens(
        IERC20 tokenAddress,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAmountNotZero(amount) {
        tokenAddress.safeTransferFrom(address(this), msg.sender, amount);
        emit TokensWithdrawn(address(this), msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getBand(uint256 tokenId) external view returns (Band memory) {
        return s_bands[tokenId];
    }

    function getMaxLevel() external view returns (uint16) {
        return s_maxLevel;
    }

    function getNextTokenId() external view returns (uint256) {
        return s_nextTokenId;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR ADMIN ROLE
    //////////////////////////////////////////////////////////////////////////*/

    function setMaxLevel(uint16 maxLevel) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (maxLevel <= s_maxLevel) {
            revert Nft__InvalidMaxLevel(maxLevel);
        }

        s_maxLevel = maxLevel;
    }

    function setLevelPricing(
        uint16 level,
        uint256 price
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (s_maxLevel < level) {
            revert Nft__InvalidMaxLevel(s_maxLevel);
        }
        s_level_pricing[level] = price;
    }

    function mintGenesisBand(
        address receiver,
        uint16 level,
        uint16 amount
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAmountNotZero(amount)
        mAddressNotZero(receiver)
    {
        // Checks: level must be valid
        if (level > s_maxLevel) {
            revert Nft__InvalidLevel(level);
        }
        uint256 tokenId;
        // Effects: mint genesis band
        for (uint256 i = 0; i < amount; i++) {
            tokenId = ++s_nextTokenId;
            _safeMint(receiver, tokenId);
        }

        // Effects: set the band data
        s_bands[tokenId] = Band({level: level, isGenesis: true});

        emit BandMinted(msg.sender, tokenId, level, true);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getBandLevelCost(uint16 level) public view returns (uint256) {
        return s_level_pricing[level];
    }

    function isGenesisBand(uint256 tokenId) public view returns (bool) {
        return s_bands[tokenId].isGenesis;
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
    ) internal override onlyRole(UPGRADER_ROLE) {}

    /*//////////////////////////////////////////////////////////////////////////
                            INTERAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    function _purchaseBand(
        IERC20 tokenAddress,
        uint256 cost
    ) internal virtual mTokenExists(tokenAddress) {
        if (tokenAddress.allowance(msg.sender, address(this)) < cost)
            revert Nft__NotEnoughTokenAllowance();

        tokenAddress.safeTransferFrom(msg.sender, address(this), cost);
        emit PurchasePaid(address(tokenAddress), cost);
    }

    function _refundBandDowngrade(
        IERC20 tokenAddress,
        uint256 cost
    ) internal virtual mTokenExists(tokenAddress) {
        if (tokenAddress.allowance(address(this), msg.sender) < cost)
            revert Nft__NotEnoughTokenAllowance();

        tokenAddress.safeTransferFrom(address(this), msg.sender, cost);
        emit RefundPaid(address(tokenAddress), cost);
    }
}
