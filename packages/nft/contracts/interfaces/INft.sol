// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface INftEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event BandMinted(
        address indexed sender,
        uint256 indexed tokenId,
        uint16 level,
        bool isGenesis
    );

    event BandChanged(
        address indexed owner,
        uint256 indexed tokenId,
        uint16 oldLevel,
        uint16 newLevel
    );

    event PurchasePaid(address tokenAddress, uint256 amount);

    event RefundPaid(address tokenAddress, uint256 amount);

    event TokensWithdrawn(address from, address to, uint256 amount);
}

interface INft is INftEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Band {
        uint16 level;
        bool isGenesis;
    }
    /*//////////////////////////////////////////////////////////////////////////
                                       ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    error Nft__InvalidLevel(uint16 level);
    error Nft__InvalidMaxLevel(uint16 maxLevel);
    error Nft__InsufficientContractBalance(
        uint256 contractBalance,
        uint256 requiredAmount
    );
    error Nft__TransferFailed();
    error Nft__InvalidTokenId();
    error Nft__NotBandOwner();
    error Nft__NonExistantPayment();
    error Nft__NotEnoughTokenAllowance();
    error Nft__PassedZeroAmount();
    error Nft__ZeroAddress();
}
