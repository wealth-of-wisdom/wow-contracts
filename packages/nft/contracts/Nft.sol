// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
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
    address payable private _collectorWallet;
    mapping(uint256 => Band) internal s_bands; // token ID => band
    mapping(uint16 => uint256) internal level_pricing; // level => price in USD
    uint256 internal s_nextTokenId;
    uint16 internal s_maxLevel;
    /* solhint-enable */

    /*//////////////////////////////////////////////////////////////////////////
                                  MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/
    
    modifier mNotZero(address addr) {
        if (addr == address(0)) revert Nft__ZeroAddress();
        _;
    }
        
    modifier mTokenExists(IERC20 tokenAddress) {
        if (tokenAddress != USDTtokenAddress || tokenAddress != USDCtokenAddress) {
            revert Nft__NonExistantPayment();
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
        IERC20 USDTaddress,
        IERC20 USDCaddress
    ) public initializer  mNotZero(address(USDTaddress))
        mNotZero(address(USDCaddress)) {
        __ERC721_init(name, symbol);
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        s_maxLevel = 5;
        level_pricing[1] = 1_000;
        level_pricing[2] = 5_000;
        level_pricing[3] = 10_000;
        level_pricing[4] = 33_000;
        level_pricing[5] = 100_000;

        USDTtokenAddress = USDTaddress;
        USDCtokenAddress = USDCaddress;

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

    function setLevelPricing(uint16 level, uint256 price) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (s_maxLevel < level) {
            revert Nft__InvalidMaxLevel(s_maxLevel);
        }
        level_pricing[level] = price;
    }

    function setCollectorWallet(
        address payable collectorWallet
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (collectorWallet == address(0)) revert Nft__ZeroAddress();
        _collectorWallet = collectorWallet;
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
        uint256 tokenId = s_nextTokenId++;
        _safeMint(msg.sender, tokenId);

        // Effects: set the band data
        bool isGenesis = isGenesisBand(tokenId);
        s_bands[tokenId] = Band({level: level, isGenesis: isGenesis});

        /// @todo Handle any excess payment

        emit BandMinted(msg.sender, tokenId, level, isGenesis);
    }

    function changeBand(uint256 tokenId, uint16 newLevel, IERC20 assetAddress) external {
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
                _purchaseBand(assetAddress, upgradeCost);
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
               _refundBandDowngrade(assetAddress, downgradeRefund);
            }
        }

        /// @todo Handle any excess payment
        band.level = newLevel;

        emit BandChanged(msg.sender, tokenId, currentLevel, newLevel);
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
                            PUBLIC VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getBandLevelCost(uint16 level) public view returns (uint256) {
        /// @question What is the cost for each level? Do we want to use price feed?
        /// @todo Implement this function to return the cost for a given level
        return level_pricing[level];
    }

    function getCollectorWallet() public view returns (address) {
        return _collectorWallet;
    }

    function isGenesisBand(uint256 tokenId) public pure returns (bool) {
        /// @todo Implement this function to return true if the given token ID is a genesis band
        return false;
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
    ) internal virtual mTokenExists(tokenAddress){
        if (
            tokenAddress.allowance(msg.sender, address(this)) <
            cost
        ) revert Nft__NotEnoughTokenAllowance();

        tokenAddress.safeTransferFrom(
            msg.sender,
            _collectorWallet,
            cost
        );
        emit PurchasePaid(
            address(tokenAddress),
            cost
        );
    }

    //@todo decide fund location, either collector wallet or contact
     function _refundBandDowngrade(
        IERC20 tokenAddress,
        uint256 cost
    ) internal virtual mTokenExists(tokenAddress){
       if (
            tokenAddress.allowance(address(this), msg.sender) <
            cost
        ) revert Nft__NotEnoughTokenAllowance();

        tokenAddress.safeTransferFrom(
            address(this),
            msg.sender,
            cost
        );
        emit RefundPaid(
            address(tokenAddress),
            cost
        );
    }

}
