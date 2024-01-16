// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
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
    bytes32 public constant BAND_MANAGER = keccak256("BAND_MANAGER");

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

    modifier mValidBandLevel(uint16 level) {
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
        _grantRole(BAND_MANAGER, msg.sender);

        s_usdtToken = usdtToken;
        s_usdcToken = usdcToken;
        s_nftContract = nftContract;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS FOR USERS
    //////////////////////////////////////////////////////////////////////////*/

    function mintBand(
        uint16 level,
        IERC20 token
    ) external mValidBandLevel(level) mTokenExists(token) {
        uint256 cost = s_nftContract.getLevelData(level).price;
        uint256 tokenId = s_nftContract.getNextTokenId();

        // Effects: set the band data
        s_nftContract.setBandData(
            tokenId,
            level,
            false,
            INft.ActivityType.INACTIVE,
            block.timestamp,
            block.timestamp
        );

        // Effects: Transfer the payment to the contract
        _purchaseBand(token, cost);

        // Interaction: mint the band
        s_nftContract.safeMint(msg.sender);
        emit BandMinted(msg.sender, tokenId, level, false, block.timestamp);
    }

    function updateBand(
        uint256 tokenId,
        uint16 newLevel,
        IERC20 token
    ) external mValidBandLevel(newLevel) mTokenExists(token) {
        if (s_nftContract.ownerOf(tokenId) != msg.sender) {
            revert Errors.NftSale__NotBandOwner();
        }

        INft.Band memory bandData = s_nftContract.getBand(tokenId);
        uint16 currentLevel = bandData.level;

        // Checks: the band cannot be genesis or deactivated
        if (
            bandData.isGenesis ||
            bandData.activityType == INft.ActivityType.DEACTIVATED
        ) {
            revert Errors.NftSale__UnupdatableBand();
        }

        // Checks: the new level must be greater than current level
        if (newLevel <= currentLevel) {
            revert Errors.NftSale__InvalidLevel(newLevel);
        }

        uint256 upgradeCost = s_nftContract.getLevelData(newLevel).price -
            s_nftContract.getLevelData(currentLevel).price;

        // Effects: Update the old band data and add new band
        _updateBand(tokenId, currentLevel, newLevel);

        // Effects: Transfer the payment to the contract
        _purchaseBand(token, upgradeCost);

        // Interaction: mint the new band (we don't burn the old one)
        s_nftContract.safeMint(msg.sender);

        emit BandUpdated(msg.sender, tokenId, currentLevel, newLevel);
    }

    function mintGenesisBands(
        address[] memory receiver,
        uint16[] memory level
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (receiver.length != level.length)
            revert Errors.NftSale__MismatchInVariableLength();
        uint256 tokenId;
        for (uint256 i; i < receiver.length; i++) {
            tokenId = s_nftContract.getNextTokenId();

            // Effects: set the band data
            s_nftContract.setBandData(
                tokenId,
                level[i],
                true,
                INft.ActivityType.INACTIVE,
                block.timestamp,
                block.timestamp
            );

            // Interactions: mint genesis band
            s_nftContract.safeMint(receiver[i]);

            emit BandMinted(
                receiver[i],
                tokenId,
                level[i],
                true,
                block.timestamp
            );
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
            revert Errors.NftSale__PassedZeroAmount();
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

    function getTokenUSDT() public view returns (IERC20) {
        return s_usdtToken;
    }

    function getTokenUSDC() public view returns (IERC20) {
        return s_usdcToken;
    }

    function getNftContract() public view returns (INft) {
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

    function _purchaseBand(
        IERC20 token,
        uint256 cost
    ) internal virtual mTokenExists(token) {
        // Interaction: transfer the payment to the contract
        token.safeTransferFrom(msg.sender, address(this), cost);

        emit PurchasePaid(token, cost);
    }

    function _updateBand(
        uint256 tokenId,
        uint16 oldLevel,
        uint16 newLevel
    ) internal virtual {
        s_nftContract.setBandData(
            tokenId,
            oldLevel,
            false,
            INft.ActivityType.DEACTIVATED,
            block.timestamp,
            block.timestamp
        );

        uint256 newTokenId = s_nftContract.getNextTokenId();
        s_nftContract.setBandData(
            newTokenId,
            newLevel,
            false,
            INft.ActivityType.INACTIVE,
            block.timestamp,
            block.timestamp
        );
    }

    uint256[50] private __gap;
}
