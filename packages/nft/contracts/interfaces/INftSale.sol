// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INft} from "../interfaces/INft.sol";

interface INftSaleEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event NftMinted(
        address indexed receiver,
        uint16 level,
        bool isGenesis,
        uint256 activityEndTimestamp
    );

    event NftUpdated(
        address indexed owner,
        uint256 indexed tokenId,
        uint16 oldLevel,
        uint16 newLevel
    );

    event TokensWithdrawn(IERC20 token, address receiver, uint256 amount);

    event MaxLevelSet(uint16 newMaxLevel);

    event DivisorSet(uint256 newGenesisTokenDivisor);

    event PromotionalVestingPIDSet(uint16 newPID);

    event USDTTokenSet(IERC20 newToken);

    event USDCTokenSet(IERC20 newToken);

    event NftContractSet(INft newContract);

    event LevelDataSet(
        uint16 newLevel,
        uint256 newPrice,
        uint256 newVestingRewardWOWTokens,
        uint256 newlifecycleTimestamp,
        uint256 newlifecycleExtensionTimestamp,
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
        INft contractNFT
    ) external;

    function mintNft(uint16 level, IERC20 token) external;

    function updateNft(uint256 tokenId, uint16 newLevel, IERC20 token) external;

    function withdrawTokens(IERC20 token, uint256 amount) external;

    function mintGenesisNfts(
        address[] memory receivers,
        uint16[] memory levels
    ) external;

    function setUSDTToken(IERC20 newToken) external;

    function setUSDCToken(IERC20 newToken) external;

    function setNftContract(INft newContract) external;

    function getTokenUSDT() external view returns (IERC20);

    function getTokenUSDC() external view returns (IERC20);

    function getNftContract() external view returns (INft);
}
