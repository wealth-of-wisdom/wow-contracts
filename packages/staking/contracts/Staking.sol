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

contract StakingManager is
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
    uint24 private constant PERCENTAGE_PRECISION = 10 ** 6; // 100% = 10**6

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

    mapping(uint16 poolId => Pool) internal s_poolData; // Pool data
    mapping(uint16 bandId => Band) internal s_bandData; // Band data
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

    modifier mBandExists(uint16 bandId) {
        if (bandId == 0 || bandId > s_totalBands) {
            revert Errors.Staking__InvalidBandId(bandId);
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
        uint24 distributionPercentage,
        uint24[] memory bandAllocationPercentage
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
     * @param   bandId  band identification number
     * @param   price  band purchase price
     * @param   accessiblePools  list of pools that become
     *          accessible after band purchase
     * @param   stakingTimespan  time in months for how long
     *          staking will be conducted
     */
    function setBand(
        uint16 bandId,
        uint256 price,
        uint16[] memory accessiblePools,
        uint256 stakingTimespan
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAmountNotZero(price)
        mBandExists(bandId)
    {
        // Checks: amount must be in pool bounds
        if (accessiblePools.length > s_totalPools)
            revert Errors.Staking__MaximumLevelExceeded();

        // Checks: checks if timespan valid
        if (stakingTimespan < MONTH) {
            revert Errors.Staking__InvalidStaingTimespan(stakingTimespan);
        }

        // Effects: set band storage
        s_bandData[bandId] = Band({
            price: price,
            accessiblePools: accessiblePools,
            stakingTimespan: stakingTimespan
        });
        emit BandSet(bandId);
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

    function stake(StakingTypes stakingType, uint16 bandLevel) external {
        bytes32 hashedStakerBandAndLevel = _getStakerBandAndLevelHash(
            msg.sender,
            bandLevel
        );

        uint16 bandId = s_nextBandId[hashedStakerBandAndLevel];
        Band memory bandData = s_bandData[bandId];

        bytes32 hashedStakerWithBandLevelAndId = _getStakerWithBandLevelAndIdHash(
                msg.sender,
                bandLevel,
                bandId
            );

        // Effects: set staker and pool data
        s_stakerBand[hashedStakerWithBandLevelAndId] = StakerBandData({
            stakingType: stakingType,
            stakingStartTimestamp: block.timestamp,
            usdtRewardsClaimed: 0,
            usdcRewardsClaimed: 0
        });

        s_nextBandId[hashedStakerBandAndLevel]++;

        // s_stakerBandState[hashedStakerBandAndLevel].set(, true);

        uint16 poolId;
        for (uint i; i < bandData.accessiblePools.length; i++) {
            poolId = bandData.accessiblePools[i];
            s_poolData[poolId].userCheck[msg.sender] = true;
            s_poolData[poolId].allUsers.push(msg.sender);
        }

        // Effects: transfer transaction funds to contract
        s_wowToken.safeTransferFrom(msg.sender, address(this), bandData.price);
        bandId++;
    }

    //set data for staking

    // NOTE: staking function base
    // function addStakerToPoolIfInexistent(
    //     uint256 _poolId,
    //     address depositingStaker
    // ) private {
    //     Pool storage pool = pools[_poolId];
    //     for (uint256 i; i < pool.stakers.length; i++) {
    //         address existingStaker = pool.stakers[i];
    //         if (existingStaker == depositingStaker) return;
    //     }
    //     pool.stakers.push(msg.sender);
    // }

    // function deposit(uint256 _poolId, uint256 _amount) external {
    //     require(_amount > 0, "Deposit amount can't be zero");
    //     Pool storage pool = pools[_poolId];
    //     PoolStaker storage staker = poolStakers[_poolId][msg.sender];
    //     // Update pool stakers
    //     updateStakersRewards(_poolId);
    //     addStakerToPoolIfInexistent(_poolId, msg.sender);
    //     // Update current staker
    //     staker.amount = staker.amount + _amount;
    //     staker.lastRewardedBlock = block.number;
    //     // Update pool
    //     pool.tokensStaked = pool.tokensStaked + _amount;
    //     // Deposit tokens
    //     emit Deposit(msg.sender, _poolId, _amount);
    //     pool.stakeToken.safeTransferFrom(
    //         address(msg.sender),
    //         address(this),
    //         _amount
    //     );
    // }

    // function withdraw(uint256 _poolId) external {
    //     Pool storage pool = pools[_poolId];
    //     PoolStaker storage staker = poolStakers[_poolId][msg.sender];
    //     uint256 amount = staker.amount;
    //     require(amount > 0, "Withdraw amount can't be zero");

    //     // Update pool stakers
    //     updateStakersRewards(_poolId);

    //     // Pay rewards
    //     harvestRewards(_poolId);

    //     // Update staker
    //     staker.amount = 0;

    //     // Update pool
    //     pool.tokensStaked = pool.tokensStaked - amount;

    //     // Withdraw tokens
    //     emit Withdraw(msg.sender, _poolId, amount);
    //     pool.stakeToken.safeTransfer(address(msg.sender), amount);
    // }

    // function harvestRewards(uint256 _poolId) public {
    //     updateStakersRewards(_poolId);
    //     PoolStaker storage staker = poolStakers[_poolId][msg.sender];
    //     uint256 rewardsToHarvest = staker.rewards;
    //     staker.rewards = 0;
    //     emit HarvestRewards(msg.sender, _poolId, rewardsToHarvest);
    //     //transfer reward token rewards to user
    //     // rewardToken.mint(msg.sender, rewardsToHarvest);
    // }

    // function updateStakersRewards(uint256 _poolId) private {
    //     Pool storage pool = pools[_poolId];
    //     for (uint256 i; i < pool.stakers.length; i++) {
    //         address stakerAddress = pool.stakers[i];
    //         PoolStaker storage staker = poolStakers[_poolId][stakerAddress];
    //         if (staker.amount == 0) return;
    //         uint256 stakedAmount = staker.amount;
    //         uint256 stakerShare = ((stakedAmount * STAKER_SHARE_PRECISION) /
    //             pool.tokensStaked);
    //         uint256 blocksSinceLastReward = block.number -
    //             staker.lastRewardedBlock;
    //         uint256 rewards = (blocksSinceLastReward *
    //             rewardTokensPerBlock *
    //             stakerShare) / STAKER_SHARE_PRECISION;
    //         staker.lastRewardedBlock = block.number;
    //         staker.rewards = staker.rewards + rewards;
    //     }
    // }

    /*//////////////////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS
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
