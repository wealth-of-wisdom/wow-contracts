// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {INft} from "@wealth-of-wisdom/nft/contracts/interfaces/INft.sol";

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
    bytes32 public constant WHITELISTED_SENDER_ROLE =
        keccak256("WHITELISTED_SENDER_ROLE");
    bytes32 public constant BAND_MANAGER = keccak256("BAND_MANAGER");

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */
    mapping(uint256 => Band) internal s_bands; // token ID => band
    mapping(uint16 => NftLevel) internal s_nftLevels; // level => level data
    // level => project => project amount
    mapping(uint16 => mapping(uint8 => uint16)) internal s_projectsPerNft;
    uint16 internal s_maxLevel;
    uint16 internal s_promotionalVestingPID;
    uint256 internal s_genesisTokenDivisor;
    uint256 internal s_nextTokenId;

    /* solhint-enable */

    /*//////////////////////////////////////////////////////////////////////////
                                  MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier mAmountNotZero(uint256 amount) {
        if (amount == 0) {
            revert Errors.NftSale__PassedZeroAmount();
        }
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        uint16 maxLevel,
        uint16 promotionalVestingPID,
        uint256 genesisTokenDivisor
    ) external initializer {
        if (bytes(name).length == 0 || bytes(symbol).length == 0) {
            revert Errors.Nft__EmptyString();
        }

        __ERC721_init(name, symbol);
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(WHITELISTED_SENDER_ROLE, msg.sender);

        s_maxLevel = maxLevel;
        s_promotionalVestingPID = promotionalVestingPID;
        s_genesisTokenDivisor = genesisTokenDivisor;
    }

    function safeMint(address to) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = s_nextTokenId++;
        _safeMint(to, tokenId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR ADMIN ROLE
    //////////////////////////////////////////////////////////////////////////*/

    function setBandData(
        uint256 tokenId,
        uint16 level,
        bool isGenesis,
        ActivityType activityType
    ) external onlyRole(BAND_MANAGER) {
        s_bands[tokenId] = Band({
            level: level,
            isGenesis: isGenesis,
            activityType: activityType,
            activityTimestamp: block.timestamp
        });
    }

    function setMaxLevel(
        uint16 maxLevel
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: the new max level must be greater than the current max level
        if (maxLevel <= s_maxLevel) {
            revert Errors.NftSale__InvalidMaxLevel(maxLevel);
        }

        // Effects: set the new max level
        s_maxLevel = maxLevel;

        emit MaxLevelSet(maxLevel);
    }

    function setGenesisTokenDivisor(
        uint256 newGenesisTokenDivisor
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAmountNotZero(newGenesisTokenDivisor)
    {
        s_genesisTokenDivisor = newGenesisTokenDivisor;
        emit DivisorSet(newGenesisTokenDivisor);
    }

    function setPromotionalVestingPID(
        uint16 pid
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        s_promotionalVestingPID = pid;
        emit PromotionalVestingPIDSet(pid);
    }

    //NOTE: convert necesary lifecycle time into timestamp
    function setLevelData(
        uint16 level,
        uint256 newPrice,
        uint256 newVestingRewardWOWTokens,
        uint256 newLifecycleTimestamp,
        uint256 newLifecycleExtensionInMonths,
        uint256 newAllocationPerProject
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAmountNotZero(newPrice) {
        s_nftLevels[level] = NftLevel({
            price: newPrice,
            vestingRewardWOWTokens: newVestingRewardWOWTokens,
            lifecycleTimestamp: newLifecycleTimestamp,
            lifecycleExtensionInMonths: newLifecycleExtensionInMonths,
            allocationPerProject: newAllocationPerProject
        });
        emit LevelDataSet(
            level,
            newPrice,
            newVestingRewardWOWTokens,
            newLifecycleTimestamp,
            newLifecycleExtensionInMonths,
            newAllocationPerProject
        );
    }

    function setProjectLifecycle(
        uint16 level,
        uint8 project,
        uint16 nftLifecycleProjectAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        s_projectsPerNft[level][project] = nftLifecycleProjectAmount;
        emit ProjectPerLifecycle(level, project, nftLifecycleProjectAmount);
    }

    function setMultipleLevelLifecyclesPerProject(
        uint8 project,
        uint16[] memory nftLifecycleProjectAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (nftLifecycleProjectAmount.length != s_maxLevel)
            revert Errors.NftSale__MismatchInVariableLength();
        for (uint16 level; level < s_maxLevel; level++) {
            s_projectsPerNft[level][project] = nftLifecycleProjectAmount[level];
            emit ProjectPerLifecycle(
                level,
                project,
                nftLifecycleProjectAmount[level]
            );
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getBand(uint256 tokenId) external view returns (Band memory) {
        return s_bands[tokenId];
    }

    function getLevelData(uint16 level) public view returns (NftLevel memory) {
        return s_nftLevels[level];
    }

    function getNextTokenId() external view returns (uint256) {
        return s_nextTokenId;
    }

    function getMaxLevel() external view returns (uint16) {
        return s_maxLevel;
    }

    function getGenesisTokenDivisor() public view returns (uint256) {
        return s_genesisTokenDivisor;
    }

    function getPromotionalPID() external view returns (uint16) {
        return s_promotionalVestingPID;
    }

    function getProjectLifecycle(
        uint16 level,
        uint8 project
    ) public view returns (uint16) {
        return s_projectsPerNft[level][project];
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INHERITED OVERRIDEN FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, INft)
        onlyRole(WHITELISTED_SENDER_ROLE)
    {
        super.transferFrom(from, to, tokenId);
    }

    function ownerOf(
        uint256 s_nextTokenId
    ) public view override(ERC721Upgradeable, INft) returns (address) {
        return _requireOwned(s_nextTokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable, INft)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    // The following functions are overrides required by Solidity.
 
    uint256[50] private __gap;
}
