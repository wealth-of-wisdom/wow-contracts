// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library Errors {
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
    error Nft__PassedZeroAmount();
    error Nft__ZeroAddress();
}
