// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                    NFT
    //////////////////////////////////////////////////////////////////////////*/

    error Nft__EmptyString();

    /*//////////////////////////////////////////////////////////////////////////
                                    NFT SALE
    //////////////////////////////////////////////////////////////////////////*/
    error NftSale__InvalidLevel(uint16 level);
    error Nft__InvalidMaxLevel(uint16 maxLevel);
    error NftSale__InsufficientContractBalance(
        uint256 contractBalance,
        uint256 requiredAmount
    );
    error NftSale__TransferFailed();
    error Nft__MismatchInVariableLength();
    error NftSale__InvalidTokenId();
    error Nft__NotNftOwner();
    error NftSale__NonExistantPayment();
    error NftSale__UnupdatableNft();
    error Nft__PassedZeroAmount();
    error Nft__ZeroAddress();
    error Nft__AlreadyActivated();
    error NftSale__NotActivated();
}
