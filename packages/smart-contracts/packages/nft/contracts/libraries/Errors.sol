// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                    NFT
    //////////////////////////////////////////////////////////////////////////*/

    error Nft__InvalidMaxLevel(uint16 maxLevel);
    error Nft__InvalidLevel(uint16 level);
    error Nft__InvalidTotalProjectTypes(uint8 count);
    error Nft__InvalidProjectType(uint8 project);
    error Nft__SupplyCapTooLow(uint256 supplyCap);
    error Nft__SupplyCapReached(
        uint16 level,
        bool isGenesis,
        uint256 nftAmount
    );
    error Nft__EmptyString();
    error Nft__MismatchInVariableLength();
    error Nft__NotNftOwner();
    error Nft__ZeroAmount();
    error Nft__ZeroAddress();
    error Nft__AlreadyActivated();
    error Nft__GenesisNftNotUpdatable();
    error Nft__ReceiverNotOwner();

    /*//////////////////////////////////////////////////////////////////////////
                                    NFT SALE
    //////////////////////////////////////////////////////////////////////////*/

    error NftSale__InvalidLevel(uint16 level);
    error NftSale__InsufficientContractBalance(
        uint256 contractBalance,
        uint256 requiredAmount
    );
    error NftSale__MismatchInVariableLength();
    error NftSale__NotNftOwner();
    error NftSale__ZeroAmount();
    error NftSale__ZeroAddress();
    error NftSale__NonExistantPayment();
    error NftSale__UnupdatableNft();
}
