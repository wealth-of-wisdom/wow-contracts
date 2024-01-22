// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INftSale} from "./interfaces/INftSale.sol";
import {INft} from "./interfaces/INft.sol";
import {Errors} from "./libraries/Errors.sol";

contract NftSale is
    INftSale,
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
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

    /* solhint-disable var-name-mixedcase */
    IERC20 internal s_usdtToken;
    IERC20 internal s_usdcToken;
    INft internal s_nftContract;
    /* solhint-enable */

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

    modifier mValidLevel(uint16 level) {
        if (level == 0 || level > s_nftContract.getMaxLevel()) {
            revert Errors.NftSale__InvalidLevel(level);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract
     * @param usdtToken SDT token
     * @param usdcToken USDC token
     * @param nftContract NFT contract
     */
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

        // Effects: set the roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        // Effects: set the storage
        s_usdtToken = usdtToken;
        s_usdcToken = usdcToken;
        s_nftContract = nftContract;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS FOR USERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints a new NFT with the given level
     * @param level NFT level
     * @param token Payment token
     */
    function mintNft(
        uint16 level,
        IERC20 token
    ) external mValidLevel(level) mTokenExists(token) {
        uint256 cost = s_nftContract.getLevelData(level, false).price;

        // Effects: Transfer the payment to the contract
        _purchaseNft(token, cost);

        // Interaction: mint the nft
        s_nftContract.mintAndSetNftData(msg.sender, level, false);

        emit NftMinted(msg.sender, level, false, 0);
    }

    /**
     * @notice Update NFT to a higher level
     * @param tokenId NFT token ID to update
     * @param newLevel New NFT level (must be higher than current level)
     * @param token Payment token (USDT/USDC)
     */
    function updateNft(
        uint256 tokenId,
        uint16 newLevel,
        IERC20 token
    ) external mValidLevel(newLevel) mTokenExists(token) {
        // Checks: the sender must be the owner of the NFT
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

        uint256 upgradeCost = s_nftContract
            .getLevelData(newLevel, false)
            .price - s_nftContract.getLevelData(currentLevel, false).price;

        // Effects: Transfer the payment to the contract
        _purchaseNft(token, upgradeCost);

        // Interaction: mint the new NFT (we don't burn the old one) and udpate old and new nfts data
        s_nftContract.mintAndUpdateNftData(msg.sender, tokenId, newLevel);

        emit NftUpdated(msg.sender, tokenId, currentLevel, newLevel);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR DEFAULT ADMIN ROLE
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints a new Genesis NFT with the given level
     * @param receivers Receivers of the NFTs (must be the same length as levels)
     * @param levels NFT levels
     */
    function mintGenesisNfts(
        address[] memory receivers,
        uint16[] memory levels
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Cache length of receivers array for usage in the loop
        uint256 receiversLength = receivers.length;

        // Checks: the arrays must have the same length
        if (receiversLength != levels.length) {
            revert Errors.NftSale__MismatchInVariableLength();
        }

        for (uint256 i; i < receiversLength; i++) {
            // Interactions: mint genesis nft
            s_nftContract.mintAndSetNftData(receivers[i], levels[i], true);

            emit NftMinted(receivers[i], levels[i], true, 0);
        }
    }

    /**
     * @notice Withdraw the given amount of tokens from the contract
     * @param token Token to withdraw
     * @param amount Amount to withdraw
     */
    function withdrawTokens(
        IERC20 token,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: the amount must be greater than 0
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

    /**
     * @notice Set the USDT token
     * @param newToken New USDT token
     */
    function setUSDTToken(
        IERC20 newToken
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAddressNotZero(address(newToken)) {
        // Effects: set new token for USDT
        s_usdtToken = newToken;
        emit USDTTokenSet(newToken);
    }

    /**
     * @notice Set the USDC token
     * @param newToken New USDC token
     */
    function setUSDCToken(
        IERC20 newToken
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAddressNotZero(address(newToken)) {
        // Effects: set new token for USDC
        s_usdcToken = newToken;
        emit USDCTokenSet(newToken);
    }

    /**
     * @notice Set the NFT contract
     * @param newContract New NFT contract
     */
    function setNftContract(
        INft newContract
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAddressNotZero(address(newContract))
    {
        // Effects: set new NFT contract
        s_nftContract = newContract;
        emit NftContractSet(newContract);
    }

    /**
     * @notice Get the USDT token
     * @return USDT token
     */
    function getTokenUSDT() external view returns (IERC20) {
        return s_usdtToken;
    }

    /**
     * @notice Get the USDC token
     * @return USDC token
     */
    function getTokenUSDC() external view returns (IERC20) {
        return s_usdcToken;
    }

    /**
     * @notice Get the NFT contract
     * @return NFT contract
     */
    function getNftContract() external view returns (INft) {
        return s_nftContract;
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

    /*//////////////////////////////////////////////////////////////////////////
                            INHERITED OVERRIDEN FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The following functions are overrides required by Solidity.

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

    uint256[50] private __gap; // @question Why are we adding storage at the end of the contract?
}
