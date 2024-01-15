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
    error NftSale__InvalidMaxLevel(uint16 maxLevel);
    error NftSale__InsufficientContractBalance(
        uint256 contractBalance,
        uint256 requiredAmount
    );
    error NftSale__TransferFailed();
    error NftSale__InvalidTokenId();
    error NftSale__NotBandOwner();
    error NftSale__NonExistantPayment();
    error NftSale__UnupdatableBand();
    error NftSale__PassedZeroAmount();
    error NftSale__ZeroAddress();
    error NftSale__AlreadyActivated();
}
