// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {INft} from "@wealth-of-wisdom/nft/contracts/interfaces/INft.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";

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
        keccak256("WHITELISTED_SENDER_ROLE"); // for transfer authorization
    bytes32 public constant NFT_DATA_MANAGER = keccak256("NFT_DATA_MANAGER");

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    IVesting internal s_vestingContract;

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */
    mapping(uint256 tokenId => NftData) internal s_nftData; // token ID => nft data
    mapping(uint16 level => NftLevel) internal s_nftLevels; // level => level data
    // level => project (Standard, Premium, Limited) => project amount
    mapping(uint16 level => mapping(uint16 project => uint16 projectAmount))
        internal s_projectsPerNft;
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
        IVesting vestingContract,
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
        _grantRole(NFT_DATA_MANAGER, msg.sender);

        s_maxLevel = maxLevel;
        s_promotionalVestingPID = promotionalVestingPID;
        s_genesisTokenDivisor = genesisTokenDivisor;

        s_vestingContract = vestingContract;
    }

    function safeMint(address to) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = s_nextTokenId++;
        _safeMint(to, tokenId);
    }

    function activateNftData(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) {
            revert Errors.NftSale__NotNftOwner();
        }

        NftData memory nftData = s_nftData[tokenId];

        // Checks: data must not be activated
        if (nftData.activityType != ActivityType.NOT_ACTIVATED) {
            revert Errors.NftSale__AlreadyActivated();
        }

        // Effects: update data activity
        nftData.activityType = ActivityType.ACTIVATION_TRIGGERED;
        nftData.activityEndTimestamp =
            block.timestamp +
            s_nftLevels[nftData.level].lifecycleTimestamp;
        nftData.extendedActivityEndTimestamp =
            nftData.activityEndTimestamp +
            s_nftLevels[nftData.level].lifecycleExtensionTimestamp;

        (
            ,
            ,
            uint256 totalPoolTokenAmount,
            uint256 dedicatedPoolTokenAmount
        ) = s_vestingContract.getGeneralPoolData(s_promotionalVestingPID);
        uint256 nonDedicatedTokens = totalPoolTokenAmount -
            dedicatedPoolTokenAmount;
        NftLevel memory nftLevelData = s_nftLevels[nftData.level];

        // example calculations:
        // 200k rewards = 40k WoW tokens * ( 5k price / 1k )
        // (40k tokens per 1k spent)
        uint256 rewardTokens = nftData.isGenesis
            ? nftLevelData.vestingRewardWOWTokens *
                (nftLevelData.price / s_genesisTokenDivisor)
            : nftLevelData.vestingRewardWOWTokens;

        rewardTokens = (nonDedicatedTokens < rewardTokens)
            ? nonDedicatedTokens
            : rewardTokens;

        if (rewardTokens > 0) {
            s_vestingContract.addBeneficiary(
                s_promotionalVestingPID,
                msg.sender,
                rewardTokens
            );
        }
        emit NftDataActivated(
            msg.sender,
            tokenId,
            nftData.level,
            nftData.isGenesis,
            uint256(nftData.activityType),
            nftData.activityEndTimestamp
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR ADMIN ROLE
    //////////////////////////////////////////////////////////////////////////*/

    function setNftData(
        uint256 tokenId,
        uint16 level,
        bool isGenesis,
        ActivityType activityType,
        uint256 activityEndTimestamp,
        uint256 extendedActivityEndTimestamp
    ) public onlyRole(NFT_DATA_MANAGER) {
        s_nftData[tokenId] = NftData({
            level: level,
            isGenesis: isGenesis,
            activityType: activityType,
            activityEndTimestamp: activityEndTimestamp,
            extendedActivityEndTimestamp: extendedActivityEndTimestamp
        });
    }

    function mintAndSetNftData(
        address receiver,
        uint256 tokenId,
        uint16 level,
        bool isGenesis,
        ActivityType activityType,
        uint256 activityEndTimestamp,
        uint256 extendedActivityEndTimestamp
    ) external onlyRole(NFT_DATA_MANAGER) {
        setNftData(
            tokenId,
            level,
            isGenesis,
            activityType,
            activityEndTimestamp,
            extendedActivityEndTimestamp
        );
        this.safeMint(receiver);
    }

    function updateLevelDataAndMint(
        address receiver,
        uint256 oldtokenId,
        uint16 newLevel
    ) external onlyRole(NFT_DATA_MANAGER) {
        s_nftData[oldtokenId].activityType = ActivityType.DEACTIVATED;

        uint256 newTokenId = getNextTokenId();
        setNftData(
            newTokenId,
            newLevel,
            false,
            INft.ActivityType.NOT_ACTIVATED,
            0,
            0
        );
        this.safeMint(receiver);
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
        uint256 newlifecycleExtensionTimestamp,
        uint256 newAllocationPerProject
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAmountNotZero(newPrice) {
        s_nftLevels[level] = NftLevel({
            price: newPrice,
            vestingRewardWOWTokens: newVestingRewardWOWTokens,
            lifecycleTimestamp: newLifecycleTimestamp,
            lifecycleExtensionTimestamp: newlifecycleExtensionTimestamp,
            allocationPerProject: newAllocationPerProject
        });
        emit LevelDataSet(
            level,
            newPrice,
            newVestingRewardWOWTokens,
            newLifecycleTimestamp,
            newlifecycleExtensionTimestamp,
            newAllocationPerProject
        );
    }

    function setProjectLifecycle(
        uint16 level,
        uint8 project,
        uint16 projectsQuantityInLifecycle
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        s_projectsPerNft[level][project] = projectsQuantityInLifecycle;
        emit ProjectPerLifecycle(level, project, projectsQuantityInLifecycle);
    }

    function setMultipleLevelLifecyclesPerProject(
        uint8 project,
        uint16[] memory projectsQuantityInLifecycle
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (projectsQuantityInLifecycle.length != s_maxLevel)
            revert Errors.NftSale__MismatchInVariableLength();
        for (uint16 level; level < s_maxLevel; level++) {
            s_projectsPerNft[level][project] = projectsQuantityInLifecycle[
                level
            ];
            emit ProjectPerLifecycle(
                level,
                project,
                projectsQuantityInLifecycle[level]
            );
        }
    }

    function setVestingContract(
        IVesting newContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(newContract) == address(0)) {
            revert Errors.NftSale__ZeroAddress();
        }
        s_vestingContract = newContract;
        emit VestingContractSet(newContract);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getNftData(uint256 tokenId) public view returns (NftData memory) {
        return s_nftData[tokenId];
    }

    function getLevelData(uint16 level) public view returns (NftLevel memory) {
        return s_nftLevels[level];
    }

    function getNextTokenId() public view returns (uint256) {
        return s_nextTokenId;
    }

    function getMaxLevel() public view returns (uint16) {
        return s_maxLevel;
    }

    function getGenesisTokenDivisor() public view returns (uint256) {
        return s_genesisTokenDivisor;
    }

    function getPromotionalPID() public view returns (uint16) {
        return s_promotionalVestingPID;
    }

    function getProjectLifecycle(
        uint16 level,
        uint8 project
    ) public view returns (uint16) {
        return s_projectsPerNft[level][project];
    }

    function getVestingContract() external view returns (IVesting) {
        return s_vestingContract;
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
