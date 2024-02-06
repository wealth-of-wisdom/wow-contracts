//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IStaking} from "./interfaces/IStaking.sol";
import {Errors} from "./libraries/Errors.sol";

contract Staking is
    IStaking,
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    /*//////////////////////////////////////////////////////////////////////////
                                    LIBRARIES
    //////////////////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20; // Wrappers around ERC20 operations that throw on failure
    using EnumerableMap for EnumerableMap.UintToUintMap;

    /*//////////////////////////////////////////////////////////////////////////
                                PRIVATE CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 private constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    uint128 private constant DECIMALS = 10 ** 6;
    uint128 private constant MONTH = 30 days;
    uint48 private constant PERCENTAGE_PRECISION = 10 ** 8; // 100% = 10**8

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal s_usdtToken; // Token to be payed as reward
    IERC20 internal s_usdcToken; // Token to be payed as reward
    IERC20 internal s_wowToken; // Token to be staked

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    // Enumerable mapping equivalent to:
    // mapping(uint256 bandId => uint256 bandState)
    // With normal mapping it would look like this:
    // mapping(bytes32 stakerAndBandLevel => mapping(uint256 bandId => uint256 bandState)
    // Returns 1 or 0 as true or false values to determine whether the band exists
    mapping(bytes32 stakerAndBandLevel => EnumerableMap.UintToUintMap)
        internal s_stakerBandState;

    mapping(bytes32 stakerAndBandLevel => uint16 bandId) internal s_nextBandId;
    mapping(bytes32 stakerWithBandLevelAndId => StakerBandData)
        internal s_stakerBand;

    mapping(uint16 poolId => Pool) internal s_poolData; // Pool data, poolId - 1-9lvl
    mapping(uint16 bandLevel => Band) internal s_bandData; // Band data, bandLevel - 1-9lvl
    FundDistribution[] internal s_fundDistributionData; // Any added funds data

    uint256[] shares; // in 10**6 integrals, for divident calculation
    uint16 internal s_totalPools;
    uint16 internal s_totalBands;

    /*//////////////////////////////////////////////////////////////////////////
                            STORAGE FOR FUTURE UPGRADES
    //////////////////////////////////////////////////////////////////////////*/

    uint256[50] private __gap;

    /*//////////////////////////////////////////////////////////////////////////
                                  MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier mAddressNotZero(address addr) {
        if (addr == address(0)) {
            revert Errors.Staking__ZeroAddress();
        }
        _;
    }

    modifier mAmountNotZero(uint256 amount) {
        if (amount == 0) {
            revert Errors.Staking__ZeroAmount();
        }
        _;
    }

    modifier mPoolExists(uint16 poolId) {
        if (poolId == 0 || poolId > s_totalPools) {
            revert Errors.Staking__InvalidPoolId(poolId);
        }
        _;
    }

    modifier mBandExists(uint16 bandLevel) {
        if (bandLevel == 0 || bandLevel > s_totalBands) {
            revert Errors.Staking__InvalidBand(bandLevel);
        }
        _;
    }

    modifier mTokenExists(IERC20 token) {
        if (token != s_usdtToken && token != s_usdcToken) {
            revert Errors.Staking__NonExistantToken();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        IERC20 usdtToken,
        IERC20 usdcToken,
        IERC20 wowToken,
        uint16 totalPools,
        uint16 totalBands
    )
        external
        initializer
        mAddressNotZero(address(usdtToken))
        mAddressNotZero(address(usdcToken))
        mAddressNotZero(address(wowToken))
        mAmountNotZero(totalPools)
        mAmountNotZero(totalBands)
    {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        // Effects: set the roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        // Effects: set the storage
        s_usdtToken = usdtToken;
        s_usdcToken = usdcToken;
        s_wowToken = wowToken;

        s_totalPools = totalPools;
        s_totalBands = totalBands;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS FOR DEFAULT ADMIN
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Set data for a pool which will be used for rewards distribution
     * @notice There can be only one pool with the same id
     * @notice When called for the first time, the pool will be created
     * @notice When called for the second time, the pool data will be overwritten
     * @param poolId Id of the pool (1-9)
     * @param distributionPercentage Percentage of the total rewards to be distributed to this pool
     * @param bandAllocationPercentage Percentage of the pool to be distributed to each band
     */
    function setPool(
        uint16 poolId,
        uint48 distributionPercentage,
        uint48[] memory bandAllocationPercentage
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mPoolExists(poolId) {
        // Checks: distribution percentage should not exceed 100%
        if (distributionPercentage > PERCENTAGE_PRECISION) {
            revert Errors.Staking__InvalidDistributionPercentage(
                distributionPercentage
            );
        }
        // Effects: set the storage
        Pool storage pool = s_poolData[poolId];
        pool.distributionPercentage = distributionPercentage;
        pool.bandAllocationPercentage = bandAllocationPercentage;

        // Effects: emit event
        emit PoolSet(poolId);
    }

    /**
     * @notice  Sets data of the selected band
     * @param   bandLevel  band level number
     * @param   price  band purchase price
     * @param   accessiblePools  list of pools that become
     *          accessible after band purchase
     * @param   stakingTimespan  time in months for how long
     *          staking will be conducted
     */
    function setBand(
        uint16 bandLevel,
        uint256 price,
        uint16[] memory accessiblePools,
        uint256 stakingTimespan
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAmountNotZero(price)
        mBandExists(bandLevel)
    {
        // Checks: amount must be in pool bounds
        if (accessiblePools.length > s_totalPools)
            revert Errors.Staking__MaximumLevelExceeded();

        // Checks: checks if timespan valid
        if (stakingTimespan < MONTH) {
            revert Errors.Staking__InvalidStakingTimespan(stakingTimespan);
        }

        // Effects: set band storage
        s_bandData[bandLevel] = Band({
            price: price,
            accessiblePools: accessiblePools,
            stakingTimespan: stakingTimespan
        });

        // Effects: emit event
        emit BandSet(bandLevel);
    }

    /**
     * @notice  Sets new total amount of bands used for staking
     * @param   newTotalBandsAmount  total amount of bands used for staking
     */
    function setTotalBandAmount(
        uint16 newTotalBandsAmount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAmountNotZero(newTotalBandsAmount)
    {
        s_totalBands = newTotalBandsAmount;
        emit TotalBandAmountSet(newTotalBandsAmount);
    }

    /**
     * @notice  Sets new total amount of pools used for staking
     * @param   newTotalPoolAmount  total amount of pools used for staking
     */
    function setTotalPoolAmount(
        uint16 newTotalPoolAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAmountNotZero(newTotalPoolAmount) {
        s_totalPools = newTotalPoolAmount;
        emit TotalPoolAmountSet(newTotalPoolAmount);
    }

    /**
     * @notice  Administrator function for transfering funds
     *          to contract for pool distribution
     * @param   token  USDT/USDC token
     * @param   amount  amount to be distributed to pools
     * @param   distributionPeriodStart  when distribution period started
     * @param   distributionPeriodEnd  when the distribution period ends
     */
    function distributeFunds(
        IERC20 token,
        uint256 amount,
        uint256 distributionPeriodStart,
        uint256 distributionPeriodEnd
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mTokenExists(token)
        mAmountNotZero(amount)
        mAmountNotZero(distributionPeriodStart)
        mAmountNotZero(distributionPeriodEnd)
    {
        // Effects: set fund distribution data
        FundDistribution memory fundDistributionData = FundDistribution({
            token: token,
            amount: amount,
            distributionPeriodStart: distributionPeriodStart,
            distributionPeriodEnd: distributionPeriodEnd
        });
        s_fundDistributionData.push(fundDistributionData);

        // Effects: distribute funds to pools
        uint16 totalPools = s_totalPools;
        for (uint16 poolId; poolId < totalPools; poolId++) {
            // amount * (100% * 10**6) / (distribution % * 10**6)
            uint256 poolAmount = ((amount *
                s_poolData[poolId].distributionPercentage) /
                PERCENTAGE_PRECISION);

            if (token == s_usdtToken) {
                s_poolData[poolId].totalUsdtPoolTokenAmount += poolAmount;
            } else {
                s_poolData[poolId].totalUsdcPoolTokenAmount += poolAmount;
            }
        }

        // Interaction: transfer the tokens to contract
        token.safeTransferFrom(msg.sender, address(this), amount);

        emit FundsDistributed(token, amount);
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
            revert Errors.Staking__ZeroAmount();
        }

        uint256 balance = token.balanceOf(address(this));

        // Checks: the contract must have enough balance to withdraw
        if (balance < amount) {
            revert Errors.Staking__InsufficientContractBalance(balance, amount);
        }

        // Interaction: transfer the tokens to the sender
        token.safeTransfer(msg.sender, amount);

        emit TokensWithdrawn(token, msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Stake and lock tokens to earn rewards
     * @param   stakingType  enumerable type for flexi or fixed staking
     * @param   bandLevel  band level number
     */
    function stake(
        StakingTypes stakingType,
        uint16 bandLevel
    ) external mBandExists(bandLevel) {
        if (
            StakingTypes.FIX != stakingType || StakingTypes.FLEXI != stakingType
        ) revert Errors.Staking__InvalidStakingType();

        bytes32 hashedStakerBandAndLevel = _getStakerBandAndLevelHash(
            msg.sender,
            bandLevel
        );

        uint16 bandId = s_nextBandId[hashedStakerBandAndLevel]++;
        Band memory bandData = s_bandData[bandLevel];

        bytes32 hashedStakerWithBandLevelAndId = _getStakerWithBandLevelAndIdHash(
                msg.sender,
                bandLevel,
                bandId
            );

        // Effects: set staker and pool data
        StakerBandData storage stakerBandData = s_stakerBand[
            hashedStakerWithBandLevelAndId
        ];
        stakerBandData.stakingType = stakingType;
        stakerBandData.stakingStartTimestamp = block.timestamp;

        s_stakerBandState[hashedStakerBandAndLevel].set(bandId, 1);

        uint16 poolId;
        uint256 accessiblePoolLength = bandData.accessiblePools.length;
        for (uint i; i < accessiblePoolLength; i++) {
            poolId = bandData.accessiblePools[i];
            s_poolData[poolId].userCheck[msg.sender] = true;
            s_poolData[poolId].allUsers.push(msg.sender);
        }

        // Interaction: transfer transaction funds to contract
        s_wowToken.safeTransferFrom(msg.sender, address(this), bandData.price);
    }

    /**
     * @notice  Unstake tokens at any time and claim earned rewards
     * @param   bandLevel  band level number
     * @param   bandId  Id of the band (0-max uint)
     */
    function unStake(
        uint16 bandLevel,
        uint16 bandId
    ) external mBandExists(bandLevel) {
        Band memory bandData = s_bandData[bandLevel];
        bytes32 hashedStakerBandAndLevel = _getStakerBandAndLevelHash(
            msg.sender,
            bandLevel
        );

        if (s_stakerBandState[hashedStakerBandAndLevel].get(bandId) == 0) {
            revert Errors.Staking__InvalidBandId(bandId);
        }

        // Effects: set staker and pool data
        s_stakerBandState[hashedStakerBandAndLevel].set(bandId, 0);

        uint16 poolId;
        uint256 allUsersLength;
        for (uint i; i < bandData.accessiblePools.length; i++) {
            poolId = bandData.accessiblePools[i];
            s_poolData[poolId].userCheck[msg.sender] = false;

            allUsersLength = s_poolData[poolId].allUsers.length;
            for (uint j; j < allUsersLength; j++) {
                if (s_poolData[poolId].allUsers[j] == msg.sender) {
                    s_poolData[poolId].allUsers[j] = s_poolData[poolId]
                        .allUsers[allUsersLength - 1];
                    s_poolData[poolId].allUsers.pop();
                }
            }
        }

        // Interaction: transfer transaction funds to user
        // @todo:
        // _claimRewards();
        // s_wowToken.safeTransferFrom(address(this), msg.sender, rewards+band.price);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the USDT token which is used for rewards distribution
     * @return IERC20 USDT token
     */
    function getTokenUSDT() external view returns (IERC20) {
        return s_usdtToken;
    }

    /**
     * @notice Returns the USDC token which is used for rewards distribution
     * @return IERC20 USDC token
     */
    function getTokenUSDC() external view returns (IERC20) {
        return s_usdcToken;
    }

    /**
     * @notice Returns the WOW token which is used staking by users
     * @return IERC20 WOW token
     */
    function getTokenWOW() external view returns (IERC20) {
        return s_wowToken;
    }

    /**
     * @notice Returns the total amount of pools users can stake in
     * @return uint16 Total amount of pools
     */
    function getTotalPools() external view returns (uint16) {
        return s_totalPools;
    }

    /**
     * @notice Returns the total amount of bands users can buy for staking
     * @return uint16 Total amount of bands
     */
    function getTotalBands() external view returns (uint16) {
        return s_totalBands;
    }

    function getPool(
        uint16 poolId
    )
        external
        view
        returns (
            uint48 distributionPercentage,
            uint48[] memory bandAllocationPercentage,
            uint256 usdtTokenAmount,
            uint256 usdcTokenAmount,
            address[] memory allUsers
        )
    {
        Pool storage pool = s_poolData[poolId];
        distributionPercentage = pool.distributionPercentage;
        bandAllocationPercentage = pool.bandAllocationPercentage;
        usdtTokenAmount = pool.totalUsdtPoolTokenAmount;
        usdcTokenAmount = pool.totalUsdcPoolTokenAmount;
        allUsers = pool.allUsers;
    }

    function getBand(
        uint16 bandId
    )
        external
        view
        returns (
            uint256 price,
            uint16[] memory accessiblePools,
            uint256 stakingTimespan
        )
    {
        Band storage band = s_bandData[bandId];
        price = band.price;
        accessiblePools = band.accessiblePools;
        stakingTimespan = band.stakingTimespan;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _getStakerBandAndLevelHash(
        address staker,
        uint16 bandLevel
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(staker, bandLevel));
    }

    function _getStakerWithBandLevelAndIdHash(
        address staker,
        uint16 bandLevel,
        uint16 bandId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(staker, bandLevel, bandId));
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR UPGRADER ROLE
    //////////////////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {
        /// @dev This function is empty but uses a modifier to restrict access
    }
}
