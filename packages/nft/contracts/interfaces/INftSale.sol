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
        bool isGenesis,
        uint256 activityType,
        uint256 activityTimestamp
    );

    event BandUpdated(
        uint256 indexed tokenId,
        uint256 activityType,
        uint256 activityTimestamp
    );

    event TokensWithdrawn(IERC20 token, address receiver, uint256 amount);

    event MaxLevelSet(uint16 newMaxLevel);

    event DivisorSet(uint256 newGenesisTokenDivisor);

    event PromotionalVestingPIDSet(uint16 newPID);

    event USDTTokenSet(IERC20 newToken);

    event USDCTokenSet(IERC20 newToken);

    event VestingContractSet(IVesting newContract);

    event NftContractSet(INft newContract);

    event LevelDataSet(
        uint16 newLevel,
        uint256 newPrice,
        uint256 newVestingRewardWOWTokens,
        uint256 newlifecycleTimestamp,
        uint256 newLifecycleExtensionInMonths,
        uint256 allocationPerProject
    );

    event PurchasePaid(IERC20 token, uint256 amount);

    event RefundPaid(IERC20 token, uint256 amount);
}

interface INftSale is INftSaleEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                      FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        IERC20 tokenUSDT,
        IERC20 tokenUSDC,
        INft contractNFT,
        IVesting contractVesting
    ) external;

    function mintBand(uint16 level, IERC20 token) external;

    function updateBand(
        uint256 tokenId,
        uint16 newLevel,
        IERC20 token
    ) external;

    function activateBand(uint256 tokenId) external;

    function deactivateBandOnExpiration(uint256 tokenId) external;

    function extendBand(uint256 tokenId) external;

    function withdrawTokens(IERC20 token, uint256 amount) external;

    function mintGenesisBands(
        address[] memory receiver,
        uint16[] memory level
    ) external;

    function setUSDTToken(IERC20 newToken) external;

    function setUSDCToken(IERC20 newToken) external;

    function setVestingContract(IVesting newContract) external;

    function setNftContract(INft newContract) external;

    function getTokenUSDT() external view returns (IERC20);

    function getTokenUSDC() external view returns (IERC20);

    function getNftContract() external view returns (INft);

    function getVestingContract() external view returns (IVesting);
}
