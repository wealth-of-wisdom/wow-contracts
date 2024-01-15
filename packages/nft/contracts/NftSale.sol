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
    IVesting internal s_vestingContract;

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */
    mapping(uint256 => Band) internal s_bands; // token ID => band
    mapping(uint16 => NftLevel) internal s_nftLevels; // level => level data
    // level => project => project amount
    mapping(uint16 => mapping(uint8 => uint16)) internal s_projectsPerNft;
    uint16 internal s_maxLevel;
    uint16 internal s_promotionalVestingPID;
    uint256 internal s_genesisTokenDivisor;

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

    modifier mAmountNotZero(uint256 amount) {
        if (amount == 0) {
            revert Errors.NftSale__PassedZeroAmount();
        }
        _;
    }

    modifier mValidBandLevel(uint16 level) {
        if (level == 0 || level > s_maxLevel) {
            revert Errors.NftSale__InvalidLevel(level);
        }
        _;
    }

    modifier mBandOwner(uint256 tokenId) {
        if (s_nftContract.ownerOf(tokenId) != msg.sender) {
            revert Errors.NftSale__NotBandOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        IERC20 usdtToken,
        IERC20 usdcToken,
        INft nftContract,
        IVesting vestingContract,
        uint16 maxLevel,
        uint16 promotionalVestingPID,
        uint256 genesisTokenDivisor
    )
        external
        initializer
        mAddressNotZero(address(usdtToken))
        mAddressNotZero(address(usdcToken))
        mAddressNotZero(address(nftContract))
        mAddressNotZero(address(vestingContract))
    {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(BAND_MANAGER, msg.sender);

        s_maxLevel = maxLevel;
        s_promotionalVestingPID = promotionalVestingPID;
        s_genesisTokenDivisor = genesisTokenDivisor;

        s_usdtToken = usdtToken;
        s_usdcToken = usdcToken;
        s_nftContract = nftContract;
        s_vestingContract = vestingContract;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS FOR USERS
    //////////////////////////////////////////////////////////////////////////*/

    function mintBand(
        uint16 level,
        IERC20 token
    ) external mValidBandLevel(level) mTokenExists(token) {
        uint256 cost = s_nftLevels[level].price;

        // Effects: set the band data
        uint256 tokenId = s_nftContract.getNextTokenId();
        s_bands[tokenId] = Band({
            level: level,
            isGenesis: false,
            activityType: ActivityType.INACTIVE,
            activityTimestamp: block.timestamp
        });

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
    )
        external
        mValidBandLevel(newLevel)
        mTokenExists(token)
        mBandOwner(tokenId)
    {
        Band storage band = s_bands[tokenId];
        uint16 currentLevel = band.level;

        // Checks: the band cannot be genesis or deactivated
        if (
            s_bands[tokenId].isGenesis ||
            s_bands[tokenId].activityType == ActivityType.DEACTIVATED
        ) {
            revert Errors.NftSale__UnupdatableBand();
        }

        // Checks: the new level must be greater than current level
        if (newLevel <= currentLevel) {
            revert Errors.NftSale__InvalidLevel(newLevel);
        }

        uint256 upgradeCost = s_nftLevels[newLevel].price -
            s_nftLevels[currentLevel].price;

        // Effects: Update the old band data and add new band
        _updateBand(tokenId, newLevel);

        // Effects: Transfer the payment to the contract
        _purchaseBand(token, upgradeCost);

        // Interaction: mint the new band (we don't burn the old one)
        s_nftContract.safeMint(msg.sender);

        emit BandUpdated(msg.sender, tokenId, currentLevel, newLevel);
    }

    function activateBand(uint256 tokenId) external mBandOwner(tokenId) {
        Band memory bandData = s_bands[tokenId];

        // Checks: the band must not be activated
        if (
            bandData.activityType == ActivityType.ACTIVATED ||
            bandData.activityType == ActivityType.EXTENDED
        ) {
            revert Errors.NftSale__AlreadyActivated();
        }

        // Effects: update the band activity
        s_bands[tokenId].activityType = ActivityType.ACTIVATED;
        s_bands[tokenId].activityTimestamp = block.timestamp;

        (, , , uint256 vestingPoolBalance) = s_vestingContract
            .getGeneralPoolData(s_promotionalVestingPID);
        NftLevel memory nftLevelData = s_nftLevels[bandData.level];

        uint256 rewardTokens = bandData.isGenesis
            ? (nftLevelData.vestingRewardWOWTokens * nftLevelData.price) /
                s_genesisTokenDivisor
            : nftLevelData.vestingRewardWOWTokens;

        rewardTokens = (vestingPoolBalance < rewardTokens)
            ? vestingPoolBalance
            : rewardTokens;

        if (rewardTokens > 0) {
            s_vestingContract.addBeneficiary(
                s_promotionalVestingPID,
                msg.sender,
                rewardTokens
            );
        }
        emit BandActivated(
            msg.sender,
            tokenId,
            bandData.level,
            bandData.isGenesis,
            uint256(bandData.activityType),
            bandData.activityTimestamp
        );
    }

    function deactivateBandOnExpiration(
        uint256 tokenId
    ) external onlyRole(BAND_MANAGER) {
        Band memory bandData = s_bands[tokenId];

        // Checks: the band must be activated
        if (
            (bandData.activityType == ActivityType.ACTIVATED &&
                bandData.activityTimestamp +
                    s_nftLevels[bandData.level].lifecycleTimestamp >=
                block.timestamp) ||
            (bandData.activityType == ActivityType.EXTENDED &&
                bandData.activityTimestamp +
                    s_nftLevels[bandData.level].lifecycleExtensionInMonths >=
                block.timestamp)
        ) {
            // Effects: update the band activity
            s_bands[tokenId].activityType = ActivityType.DEACTIVATED;
            s_bands[tokenId].activityTimestamp = block.timestamp;
        } else {
            revert Errors.NftSale__NotActivated();
        }

        emit BandUpdated(
            tokenId,
            uint256(bandData.activityType),
            bandData.activityTimestamp
        );
    }

    function extendBand(uint256 tokenId) external onlyRole(BAND_MANAGER) {
        Band memory bandData = s_bands[tokenId];

        // Checks: the band must be activated and timestamp passed
        if (
            bandData.activityType != ActivityType.ACTIVATED &&
            bandData.activityTimestamp +
                s_nftLevels[bandData.level].lifecycleExtensionInMonths <
            block.timestamp
        ) {
            revert Errors.NftSale__NotActivated();
        }
        s_bands[tokenId].activityType = ActivityType.EXTENDED;
        s_bands[tokenId].activityTimestamp = block.timestamp;

        emit BandUpdated(
            tokenId,
            uint256(bandData.activityType),
            bandData.activityTimestamp
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR ADMIN ROLE
    //////////////////////////////////////////////////////////////////////////*/

    function withdrawTokens(
        IERC20 token,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAmountNotZero(amount) {
        uint256 balance = token.balanceOf(address(this));

        // Checks: the contract must have enough balance to withdraw
        if (balance < amount) {
            revert Errors.NftSale__InsufficientContractBalance(balance, amount);
        }

        // Interaction: transfer the tokens to the sender
        token.safeTransfer(msg.sender, amount);

        emit TokensWithdrawn(token, msg.sender, amount);
    }

    function setMaxLevel(
        uint16 maxLevel
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: the new max level must be greater than the current max level
        if (maxLevel <= s_maxLevel) {
            revert Errors.NftSale__InvalidMaxLevel(maxLevel);
        }

        // Effects: set the new max level
        s_maxLevel = maxLevel;

        emit MaxLevelSet(maxLevel);
    }

    function setGenesisTokenDivisor(
        uint256 newGenesisTokenDivisor
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAmountNotZero(newGenesisTokenDivisor)
    {
        s_genesisTokenDivisor = newGenesisTokenDivisor;
        emit DivisorSet(newGenesisTokenDivisor);
    }

    function setPromotionalVestingPID(
        uint16 pid
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        s_promotionalVestingPID = pid;
        emit PromotionalVestingPIDSet(pid);
    }

    //NOTE: convert necesary lifecycle time into timestamp
    function setLevelData(
        uint16 level,
        uint256 newPrice,
        uint256 newVestingRewardWOWTokens,
        uint256 newLifecycleTimestamp,
        uint256 newLifecycleExtensionInMonths,
        uint256 newAllocationPerProject
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAmountNotZero(newPrice) {
        s_nftLevels[level] = NftLevel({
            price: newPrice,
            vestingRewardWOWTokens: newVestingRewardWOWTokens,
            lifecycleTimestamp: newLifecycleTimestamp,
            lifecycleExtensionInMonths: newLifecycleExtensionInMonths,
            allocationPerProject: newAllocationPerProject
        });
        emit LevelDataSet(
            level,
            newPrice,
            newVestingRewardWOWTokens,
            newLifecycleTimestamp,
            newLifecycleExtensionInMonths,
            newAllocationPerProject
        );
    }

    function setProjectLifecycle(
        uint16 level,
        uint8 project,
        uint16 nftLifecycleProjectAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        s_projectsPerNft[level][project] = nftLifecycleProjectAmount;
        emit ProjectPerLifecycle(level, project, nftLifecycleProjectAmount);
    }

    function setMultipleKevekLifecyclesPerProject(
        uint8 project,
        uint16[] memory nftLifecycleProjectAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (nftLifecycleProjectAmount.length != s_maxLevel)
            revert Errors.NftSale__MismatchInVariableLength();
        for (uint16 level; level < s_maxLevel; level++) {
            s_projectsPerNft[level][project] = nftLifecycleProjectAmount[level];
            emit ProjectPerLifecycle(
                level,
                project,
                nftLifecycleProjectAmount[level]
            );
        }
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

    function setVestingContract(
        IVesting newContract
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAddressNotZero(address(newContract))
    {
        s_vestingContract = newContract;
        emit VestingContractSet(newContract);
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

    function mintGenesisBands(
        address[] memory receiver,
        uint16[] memory level
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (receiver.length != level.length)
            revert Errors.NftSale__MismatchInVariableLength();
        for (uint256 i; i < receiver.length; i++) {
            uint256 tokenId = s_nftContract.getNextTokenId();

            // Effects: set the band data
            s_bands[tokenId] = Band({
                level: level[i],
                isGenesis: true,
                activityType: ActivityType.INACTIVE,
                activityTimestamp: block.timestamp
            });

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
                            EXTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getTokenUSDT() external view returns (IERC20) {
        return s_usdtToken;
    }

    function getTokenUSDC() external view returns (IERC20) {
        return s_usdcToken;
    }

    function getNftContract() external view returns (INft) {
        return s_nftContract;
    }

    function getVestingContract() external view returns (IVesting) {
        return s_vestingContract;
    }

    function getBand(uint256 tokenId) external view returns (Band memory) {
        return s_bands[tokenId];
    }

    function getMaxLevel() external view returns (uint16) {
        return s_maxLevel;
    }

    function getGenesisTokenDivisor() public view returns (uint256) {
        return s_genesisTokenDivisor;
    }

    function getPromotionalPID() external view returns (uint16) {
        return s_promotionalVestingPID;
    }

    function getLevelData(uint16 level) public view returns (NftLevel memory) {
        return s_nftLevels[level];
    }

    function getProjectLifecycle(
        uint16 level,
        uint8 project
    ) public view returns (uint16) {
        return s_projectsPerNft[level][project];
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

    function _updateBand(uint256 tokenId, uint16 newLevel) internal virtual {
        s_bands[tokenId].activityType = ActivityType.DEACTIVATED;
        s_bands[tokenId].activityTimestamp = block.timestamp;

        uint256 newTokenId = s_nftContract.getNextTokenId();
        s_bands[newTokenId] = Band({
            level: newLevel,
            isGenesis: false,
            activityType: ActivityType.INACTIVE,
            activityTimestamp: block.timestamp
        });
    }

    uint256[50] private __gap;
}
