// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {INft} from "@wealth-of-wisdom/nft/contracts/interfaces/INft.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";

contract NftSale is
    INftSale,
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    //test push
    /*//////////////////////////////////////////////////////////////////////////
                                    LIBRARIES
    //////////////////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal s_usdtToken;
    IERC20 internal s_usdcToken;
    INft internal s_nftContract;

    /*//////////////////////////////////////////////////////////////////////////
                                  MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier mAddressNotZero(address addr) {
        if (addr == address(0)) {
            revert Errors.NftSale__ZeroAddress();
        }
        _;
    }

    modifier mTokenExists(IERC20 token) {
        if (token != s_usdtToken && token != s_usdcToken) {
            revert Errors.NftSale__NonExistantPayment();
        }
        _;
    }

    modifier mValidNftLevel(uint16 level) {
        if (level == 0 || level > s_nftContract.getMaxLevel()) {
            revert Errors.NftSale__InvalidLevel(level);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        IERC20 usdtToken,
        IERC20 usdcToken,
        INft nftContract
    )
        external
        initializer
        mAddressNotZero(address(usdtToken))
        mAddressNotZero(address(usdcToken))
        mAddressNotZero(address(nftContract))
    {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        s_usdtToken = usdtToken;
        s_usdcToken = usdcToken;
        s_nftContract = nftContract;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS FOR USERS
    //////////////////////////////////////////////////////////////////////////*/

    function mintNft(
        uint16 level,
        IERC20 token
    ) external mValidNftLevel(level) mTokenExists(token) {
        uint256 cost = s_nftContract.getLevelData(level).price;

        // Effects: Transfer the payment to the contract
        _purchaseNft(token, cost);

        // Effects: set nft data
        // Interaction: mint the nft
        s_nftContract.mintAndSetNftData(msg.sender, level, false);

        emit NftMinted(msg.sender, level, false, 0);
    }

    function updateNft(
        uint256 tokenId,
        uint16 newLevel,
        IERC20 token
    ) external mValidNftLevel(newLevel) mTokenExists(token) {
        if (s_nftContract.ownerOf(tokenId) != msg.sender) {
            revert Errors.NftSale__NotNftOwner();
        }

        INft.NftData memory nftData = s_nftContract.getNftData(tokenId);
        uint16 currentLevel = nftData.level;

        // Checks: data cannot be genesis or deactivated
        if (
            nftData.isGenesis ||
            nftData.activityType == INft.ActivityType.DEACTIVATED ||
            (nftData.activityType == INft.ActivityType.ACTIVATION_TRIGGERED &&
                nftData.activityEndTimestamp <= block.timestamp)
        ) {
            revert Errors.NftSale__UnupdatableNft();
        }

        // Checks: the new level must be greater than current level
        if (newLevel <= currentLevel) {
            revert Errors.NftSale__InvalidLevel(newLevel);
        }

        uint256 upgradeCost = s_nftContract.getLevelData(newLevel).price -
            s_nftContract.getLevelData(currentLevel).price;

        // Effects: Transfer the payment to the contract
        _purchaseNft(token, upgradeCost);

        // Effects: Update the old data and add new nft data
        // Interaction: mint the new data (we don't burn the old one)
        s_nftContract.updateLevelDataAndMint(msg.sender, tokenId, newLevel);

        emit NftUpdated(msg.sender, tokenId, currentLevel, newLevel);
    }

    function mintGenesisNfts(
        address[] memory receivers,
        uint16[] memory levels
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (receivers.length != levels.length)
            revert Errors.NftSale__MismatchInVariableLength();
        for (uint256 i; i < receivers.length; i++) {
            // Effects: set nft data
            // Interactions: mint genesis nft
            s_nftContract.mintAndSetNftData(receivers[i], levels[i], true);

            emit NftMinted(receivers[i], levels[i], true, 0);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR ADMIN ROLE
    //////////////////////////////////////////////////////////////////////////*/

    function withdrawTokens(
        IERC20 token,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (amount == 0) {
            revert Errors.NftSale__ZeroAmount();
        }
        uint256 balance = token.balanceOf(address(this));

        // Checks: the contract must have enough balance to withdraw
        if (balance < amount) {
            revert Errors.NftSale__InsufficientContractBalance(balance, amount);
        }

        // Interaction: transfer the tokens to the sender
        token.safeTransfer(msg.sender, amount);

        emit TokensWithdrawn(token, msg.sender, amount);
    }

    function setUSDTToken(
        IERC20 newToken
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAddressNotZero(address(newToken)) {
        s_usdtToken = newToken;
        emit USDTTokenSet(newToken);
    }

    function setUSDCToken(
        IERC20 newToken
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAddressNotZero(address(newToken)) {
        s_usdcToken = newToken;
        emit USDCTokenSet(newToken);
    }

    function setNftContract(
        INft newContract
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAddressNotZero(address(newContract))
    {
        s_nftContract = newContract;
        emit NftContractSet(newContract);
    }

    function getTokenUSDT() external view returns (IERC20) {
        return s_usdtToken;
    }

    function getTokenUSDC() external view returns (IERC20) {
        return s_usdcToken;
    }

    function getNftContract() external view returns (INft) {
        return s_nftContract;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                OVERRIDE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    // The following functions are overrides required by Solidity.

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR UPGRADER ROLE
    //////////////////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {
        /// @dev This function is empty but uses a modifier to restrict access
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _purchaseNft(
        IERC20 token,
        uint256 cost
    ) internal virtual mTokenExists(token) {
        // Interaction: transfer the payment to the contract
        token.safeTransferFrom(msg.sender, address(this), cost);

        emit PurchasePaid(token, cost);
    }

    uint256[50] private __gap;
}
