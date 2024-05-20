// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";

interface INftEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event NftMinted(
        address indexed receiver,
        uint256 indexed tokenId,
        uint16 level,
        bool isGenesis,
        uint256 idInLevel
    );

    event NftDataActivated(
        address indexed receiver,
        uint256 indexed tokenId,
        uint16 level,
        bool isGenesis,
        uint256 activityEndTimestamp,
        uint256 extendedActivityEndTimestamp
    );

    event NftDataSet(
        uint256 indexed tokenId,
        uint16 level,
        bool isGenesis,
        uint256 activityType,
        uint256 activityEndTimestamp,
        uint256 extendedActivityEndTimestamp
    );

    event MaxLevelSet(uint16 newMaxLevel);

    event TotalProjectTypesSet(uint8 newCount);

    event PromotionalVestingPIDSet(uint16 newPID);

    event VestingContractSet(IVesting newContract);

    event NextTokenIdSet(uint256 nextTokenId);

    event LevelDataSet(
        uint16 level,
        bool isGenesis,
        uint256 price,
        uint256 vestingRewardWOWTokens,
        uint256 lifecycleDuration,
        uint256 extensionDuration,
        uint256 allocationPerProject,
        uint256 supplyCap,
        string baseURI
    );

    event ProjectsQuantitySet(
        uint16 level,
        bool isGenesis,
        uint8 project,
        uint16 quantity
    );

    event NftDeactivated(uint256 oldTokenId);

    event NftUpdated(
        address receiver,
        uint16 newLevel,
        uint256 oldTokenId,
        uint256 newTokenId
    );

    event MintedAndSetNftData(
        address receiver,
        uint16 level,
        bool isGenesis,
        uint256 tokenId
    );
}

interface INft is INftEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       ENUMS
    //////////////////////////////////////////////////////////////////////////*/

    enum ActivityType {
        DEACTIVATED,
        NOT_ACTIVATED,
        ACTIVATION_TRIGGERED
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct NftData {
        uint16 level;
        bool isGenesis;
        ActivityType activityType;
        uint256 activityEndTimestamp;
        uint256 extendedActivityEndTimestamp;
    }

    struct NftLevel {
        uint256 price; // Price for NFT level purchase in USDC/USDT (6 decimals)
        uint256 vestingRewardWOWTokens; // WOW Tokens (18 decimals) that will be locked into the vesting pool as a reward for purchasing this NFT level
        uint256 lifecycleDuration; // Duration of the lifecycle (in seconds)
        uint256 extensionDuration; // Duration of the lifecycle extension (in seconds)
        uint256 allocationPerProject; // Allocation per project (in USDC/USDT Tokens) for this NFT level
        uint256 nftAmount; // Amount of main/genesis NFTs that have been minted with this level
        uint256 supplyCap; // Supply cap for this level NFT
        string baseURI; // Base URI for this level NFT
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        string memory name,
        string memory symbol,
        IVesting vestingContract,
        uint16 promotionalVestingPID,
        uint16 maxLevel,
        uint8 totalProjectTypes
    ) external;

    function safeMint(address to, uint16 level, bool isGenesis) external;

    function safeMintWithTokenId(
        address to,
        uint16 level,
        bool isGenesis,
        uint256 tokenId
    ) external;

    function activateNftData(
        uint256 tokenId,
        bool isSettingVestingRewards
    ) external;

    function setNftData(
        uint256 tokenId,
        uint16 level,
        bool isGenesis,
        ActivityType activityType,
        uint256 activityEndTimestamp,
        uint256 extendedActivityEndTimestamp
    ) external;

    function mintAndSetNftData(
        address receiver,
        uint16 level,
        bool isGenesis
    ) external returns (uint256 tokenId);

    function mintAndUpdateNftData(
        address receiver,
        uint256 oldtokenId,
        uint16 newLevel
    ) external;

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

    function setMaxLevel(uint16 maxLevel) external;

    function setTotalProjectTypes(uint8 newCount) external;

    function setPromotionalVestingPID(uint16 pid) external;

    function setLevelData(
        uint16 level,
        bool isGenesis,
        uint256 price,
        uint256 vestingRewards,
        uint256 lifecycleDuration,
        uint256 extensionDuration,
        uint256 allocationPerProject,
        uint256 supplyCap,
        string calldata baseURI
    ) external;

    function setProjectsQuantity(
        uint16 level,
        bool isGenesis,
        uint8 project,
        uint16 quantity
    ) external;

    function setMultipleProjectsQuantity(
        bool isGenesis,
        uint8 project,
        uint16[] memory quantities
    ) external;

    function setVestingContract(IVesting newContract) external;

    function setNextTokenId(uint256 nextTokenId) external;

    function getNftData(uint256 tokenId) external view returns (NftData memory);

    function getLevelData(
        uint16 level,
        bool isGenesis
    ) external view returns (NftLevel memory);

    function getProjectsQuantity(
        uint16 level,
        bool isGenesis,
        uint8 project
    ) external view returns (uint16);

    function getActiveNft(address owner) external view returns (uint256);

    function getNextTokenId() external view returns (uint256);

    function getMaxLevel() external view returns (uint16);

    function getTotalProjectTypes() external view returns (uint8);

    function getPromotionalPID() external view returns (uint16);

    function getVestingContract() external view returns (IVesting);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}
