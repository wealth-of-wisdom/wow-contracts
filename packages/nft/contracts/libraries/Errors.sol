// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                    NFT
    //////////////////////////////////////////////////////////////////////////*/

    error Nft__InvalidMaxLevel(uint16 maxLevel);
    error Nft__InvalidLevel(uint16 level);
    error Nft__EmptyString();
    error Nft__MismatchInVariableLength();
    error Nft__NotNftOwner();
    error Nft__ZeroAmount();
    error Nft__ZeroAddress();
    error Nft__AlreadyActivated();

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
