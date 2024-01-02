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
}

interface INft is INftEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    error Nft__InvalidLevel(uint16 level);
    error Nft__InvalidMaxLevel(uint16 maxLevel);
    error Nft__InsufficientEthAmount(
        uint256 givenAmount,
        uint256 requiredAmount
    );
    error Nft__InsufficientContractBalance(
        uint256 contractBalance,
        uint256 requiredAmount
    );
    error Nft__TransferFailed();
    error Nft__InvalidTokenId();
    error Nft__NotBandOwner();

    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Band {
        uint16 level;
        bool isGenesis;
    }
}
