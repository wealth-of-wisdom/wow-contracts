// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";

interface INftEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event MaxLevelSet(uint16 newMaxLevel);

    event DivisorSet(uint256 newGenesisTokenDivisor);

    event PromotionalVestingPIDSet(uint16 newPID);

    event VestingContractSet(IVesting newContract);

    event NftDataActivated(
        address indexed receiver,
        uint256 indexed tokenId,
        uint16 level,
        bool isGenesis,
        uint256 activityType,
        uint256 activityEndTimestamp
    );

    event LevelDataSet(
        uint16 newLevel,
        uint256 newPrice,
        uint256 newVestingRewardWOWTokens,
        uint256 newlifecycleTimestamp,
        uint256 newlifecycleExtensionTimestamp,
        uint256 allocationPerProject
    );

    event ProjectPerLifecycle(
        uint16 level,
        uint8 project,
        uint16 projectsQuantityInLifecycle
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

    /**
     * @param price -Price for NFT level purchase
     * @param vestingRewardWOWTokens -  Tokens that will be invested into the
     * vesting pool as a reward for purchasing this NFT level
     **/
    struct NftLevel {
        uint256 price;
        uint256 vestingRewardWOWTokens;
        uint256 lifecycleTimestamp;
        uint256 lifecycleExtensionTimestamp;
        uint256 allocationPerProject;
    }

    function initialize(
        string memory name,
        string memory symbol,
        IVesting vestingContract,
        uint16 maxLevel,
        uint16 promotionalVestingPID,
        uint256 genesisTokenDivisor
    ) external;

    function safeMint(address to) external;

    function activateNftData(uint256 tokenId) external;

    function setNftData(
        uint256 tokenId,
        uint16 level,
        bool isGenesis,
        ActivityType activityType,
        uint256 activityEndTimestamp,
        uint256 extendedActivityEndTimestamp
    ) external;

    function setMaxLevel(uint16 maxLevel) external;

    function setGenesisTokenDivisor(uint256 newGenesisTokenDivisor) external;

    function setPromotionalVestingPID(uint16 pid) external;

    function setLevelData(
        uint16 newLevel,
        uint256 newPrice,
        uint256 newVestingRewardWOWTokens,
        uint256 newlifecycleTimestamp,
        uint256 newlifecycleExtensionTimestamp,
        uint256 newAllocationPerProject
    ) external;

    function setProjectLifecycle(
        uint16 level,
        uint8 project,
        uint16 projectsQuantityInLifecycle
    ) external;

    function setMultipleLevelLifecyclesPerProject(
        uint8 project,
        uint16[] memory projectsQuantityInLifecycle
    ) external;

    function setVestingContract(IVesting newContract) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function getNftData(uint256 tokenId) external view returns (NftData memory);

    function getLevelData(uint16 level) external view returns (NftLevel memory);

    function getNextTokenId() external view returns (uint256);

    function getMaxLevel() external view returns (uint16);

    function getGenesisTokenDivisor() external view returns (uint256);

    function getPromotionalPID() external view returns (uint16);

    function getProjectLifecycle(
        uint16 level,
        uint8 project
    ) external view returns (uint16);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function getVestingContract() external view returns (IVesting);
}
