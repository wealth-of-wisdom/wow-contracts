// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface INftEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event MaxLevelSet(uint16 newMaxLevel);

    event DivisorSet(uint256 newGenesisTokenDivisor);

    event PromotionalVestingPIDSet(uint16 newPID);

    event LevelDataSet(
        uint16 newLevel,
        uint256 newPrice,
        uint256 newVestingRewardWOWTokens,
        uint256 newlifecycleTimestamp,
        uint256 newLifecycleExtensionInMonths,
        uint256 allocationPerProject
    );

    event ProjectPerLifecycle(
        uint16 level,
        uint8 project,
        uint16 NftLifecycleProjectAmount
    );
}

interface INft is INftEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       ENUMS
    //////////////////////////////////////////////////////////////////////////*/

    enum ActivityType {
        DEACTIVATED,
        INACTIVE,
        ACTIVATED,
        EXTENDED
    }
    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Band {
        uint16 level;
        bool isGenesis;
        ActivityType activityType;
        uint256 activityTimestamp;
    }

    /**
     * @param price -Price for NFT level purchase
     * @param vBandActivatedestingRewardWOWTokens -  Tokens that will be invested into the
     * vesting pool as a reward for purchasing this NFT level
     **/
    struct NftLevel {
        uint256 price;
        uint256 vestingRewardWOWTokens;
        uint256 lifecycleTimestamp;
        uint256 lifecycleExtensionInMonths;
        uint256 allocationPerProject;
    }

    function initialize(
        string memory name,
        string memory symbol,
        uint16 maxLevel,
        uint16 promotionalVestingPID,
        uint256 genesisTokenDivisor
    ) external;

    function safeMint(address to) external;

    function setBandData(
        uint256 tokenId,
        uint16 level,
        bool isGenesis,
        ActivityType activityType
    ) external;

    function setMaxLevel(uint16 maxLevel) external;

    function setGenesisTokenDivisor(uint256 newGenesisTokenDivisor) external;

    function setPromotionalVestingPID(uint16 pid) external;

    function setLevelData(
        uint16 newLevel,
        uint256 newPrice,
        uint256 newVestingRewardWOWTokens,
        uint256 newlifecycleTimestamp,
        uint256 newLifecycleExtensionInMonths,
        uint256 newAllocationPerProject
    ) external;

    function setProjectLifecycle(
        uint16 level,
        uint8 project,
        uint16 NftLifecycleProjectAmount
    ) external;

    function setMultipleLevelLifecyclesPerProject(
        uint8 project,
        uint16[] memory nftLifecycleProjectAmount
    ) external;

    function getBand(uint256 tokenId) external view returns (Band memory);

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

    function transferFrom(address from, address to, uint256 tokenId) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
