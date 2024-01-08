// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Nft} from "../Nft.sol";

interface INftEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event BandMinted(
        address indexed receiver,
        uint256 indexed tokenId,
        uint16 level,
        bool isGenesis
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

    event LevelPriceSet(uint16 level, uint256 price);

    event PurchasePaid(IERC20 token, uint256 amount);

    event RefundPaid(IERC20 token, uint256 amount);
}

interface INft is INftEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       ENUMS
    //////////////////////////////////////////////////////////////////////////*/

    enum ActivityType {
        DEACTIVATED,
        INACTIVE,
        ACTIVATED
    }
    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Band {
        uint16 level;
        bool isGenesis;
        ActivityType activityType;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        IERC20 tokenUSDT,
        IERC20 tokenUSDC,
        Nft contractNFT
    ) external;

    function mintBand(uint16 level, IERC20 token) external;

    function updateBand(
        uint256 tokenId,
        uint16 newLevel,
        IERC20 token
    ) external;

    function withdrawTokens(IERC20 token, uint256 amount) external;

    function setMaxLevel(uint16 maxLevel) external;

    function setLevelPrice(uint16 level, uint256 price) external;

    function mintGenesisBand(
        address receiver,
        uint16 level,
        uint16 amount
    ) external;

    function getTokenUSDT() external view returns (IERC20);

    function getTokenUSDC() external view returns (IERC20);

    function getBand(uint256 tokenId) external view returns (Band memory);

    function getLevelPriceInUSD(uint16 level) external view returns (uint256);

    function getMaxLevel() external view returns (uint16);

    function getCurrentTokenId() external view returns (uint256);
}
