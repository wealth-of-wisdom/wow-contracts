// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
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
                                PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */
    mapping(uint256 => Band) internal s_bands; // token ID => band
    uint256 internal s_nextTokenId;
    uint16 internal s_maxLevel;

    /* solhint-enable */

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
        string memory symbol
    ) public initializer {
        __ERC721_init(name, symbol);
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        s_maxLevel = 5;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR UPGRADER ROLE
    //////////////////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR ADMIN ROLE
    //////////////////////////////////////////////////////////////////////////*/

    function setMaxLevel(uint16 maxLevel) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (maxLevel <= s_maxLevel) {
            revert Nft__InvalidMaxLevel(maxLevel);
        }

        s_maxLevel = maxLevel;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS FOR USERS
    //////////////////////////////////////////////////////////////////////////*/

    function mintBand(uint16 level) external payable {
        // Checks: level must be valid
        if (level > s_maxLevel) {
            revert Nft__InvalidLevel(level);
        }

        uint256 cost = getBandLevelCost(level);

        // Checks: eth value must be sufficient
        if (msg.value < cost) {
            revert Nft__InsufficientEthAmount(msg.value, cost);
        }

        // Effects: mint the band
        uint256 tokenId = s_nextTokenId++;
        _safeMint(msg.sender, tokenId);

        // Effects: set the band data
        bool isGenesis = isGenesisBand(tokenId);
        s_bands[tokenId] = Band({level: level, isGenesis: isGenesis});

        /// @todo Handle any excess payment

        emit BandMinted(msg.sender, tokenId, level, isGenesis);
    }

    function changeBand(uint256 tokenId, uint16 newLevel) external payable {
        if (ownerOf(tokenId) != msg.sender) {
            revert Nft__NotBandOwner();
        }

        Band storage band = s_bands[tokenId];
        uint16 currentLevel = band.level;

        if (newLevel > s_maxLevel || newLevel == currentLevel) {
            revert Nft__InvalidLevel(newLevel);
        }

        band.level = newLevel;

        if (newLevel > currentLevel) {
            uint256 upgradeCost = getBandLevelCost(newLevel) -
                getBandLevelCost(currentLevel);

            if (msg.value < upgradeCost) {
                revert Nft__InsufficientEthAmount(msg.value, upgradeCost);
            }
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
                (bool success, ) = msg.sender.call{value: downgradeRefund}("");
                if (!success) {
                    revert Nft__TransferFailed();
                }
            }
        }

        /// @todo Handle any excess payment

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

    function getBandLevelCost(uint16 level) public pure returns (uint256) {
        /// @question What is the cost for each level? Do we want to use price feed?
        /// @todo Implement this function to return the cost for a given level
        return 0.01 ether;
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
}
