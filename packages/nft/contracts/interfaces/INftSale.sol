// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {INft} from "../interfaces/INft.sol";

interface INftSaleEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event BandMinted(
        address indexed receiver,
        uint256 indexed tokenId,
        uint16 level,
        bool isGenesis,
        uint256 activityTimestamp
    );

    event BandUpdated(
        address indexed owner,
        uint256 indexed tokenId,
        uint16 oldLevel,
        uint16 newLevel
    );

    event BandActivated(
        address indexed receiver,
        uint256 indexed tokenId,
        uint16 level,
        bool isGenesis
    );

    event TokensWithdrawn(IERC20 token, address receiver, uint256 amount);

    event MaxLevelSet(uint16 newMaxLevel);

    event VestingContractSet(IVesting newContract);

    event NftContractSet(INft newContract);

    event LevelPriceSet(uint16 level, uint256 price);

    event LevelTokensSet(uint16 level, uint256 tokenAmount);

    event PurchasePaid(IERC20 token, uint256 amount);

    event RefundPaid(IERC20 token, uint256 amount);
}

interface INftSale is INftSaleEvents {
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
     * @param vestingRewardWOWTokens -  Tokens that will be invested into the
     * vesting pool as a reward for purchasing this NFT level
     **/
    struct NftLevel {
        uint256 price;
        uint256 vestingRewardWOWTokens;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        IERC20 tokenUSDT,
        IERC20 tokenUSDC,
        INft contractNFT,
        IVesting contractVesting,
        uint16 pid
    ) external;

    function mintBand(uint16 level, IERC20 token) external;

    function updateBand(
        uint256 tokenId,
        uint16 newLevel,
        IERC20 token
    ) external;

    function activateBand(uint256 tokenId) external;

    function withdrawTokens(IERC20 token, uint256 amount) external;

    function setMaxLevel(uint16 maxLevel) external;

    function setLevelPrice(uint16 level, uint256 price) external;

    function setVestingRewardWOWTokens(
        uint16 level,
        uint256 newTokenAmount
    ) external;

    function setVestingContract(IVesting newContract) external;

    function setNftContract(INft newContract) external;

    function mintGenesisBand(
        address receiver,
        uint16 level,
        uint16 amount
    ) external;

    function getTokenUSDT() external view returns (IERC20);

    function getTokenUSDC() external view returns (IERC20);

    function getNftContract() external view returns (INft);

    function getVestingContract() external view returns (IVesting);

    function getBand(uint256 tokenId) external view returns (Band memory);

    function getLevelPriceInUSD(uint16 level) external view returns (uint256);

    function getMaxLevel() external view returns (uint16);

    function getVestingRewardWOWTokens(uint16) external view returns (uint256);
}
