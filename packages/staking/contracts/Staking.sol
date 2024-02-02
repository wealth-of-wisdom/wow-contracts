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
    uint48 private constant PERCENTAGE_PRECISION = 10 ** 6; // 100% = 10**6

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

    mapping(bytes32 stakerAndBandLevel => uint256 bandId) internal s_nextBandId;

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
     * @param name Name of the pool (e.g. "Pool 1")
     * @param distributionPercentage Percentage of the total rewards to be distributed to this pool
     * @param bandAllocationPercentage Percentage of the pool to be distributed to each band
     */
    function setPool(
        uint16 poolId,
        string memory name,
        uint48 distributionPercentage,
        uint48[] memory bandAllocationPercentage
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: poolId must be in range
        if (poolId == 0 || poolId > s_totalPools) {
            revert Errors.Staking__InvalidPoolId(poolId);
        }

        // Checks: distribution percentage should not exceed 100%
        if (distributionPercentage > PERCENTAGE_PRECISION) {
            revert Errors.Staking__InvalidDistributionPercentage(
                distributionPercentage
            );
        }

        // Effects: set the storage
        Pool storage pool = s_poolData[poolId];
        pool.name = name;
        pool.distributionPercentage = distributionPercentage;
        pool.bandAllocationPercentage = bandAllocationPercentage;

        // Effects: emit event
        emit PoolSet(poolId, name);
    }

    /**
     * @notice  Sets data of the selected band
     * @param   bandId  band identification number
     * @param   price  band purchase price
     * @param   accessiblePools  list of pools that become
     *          accessible after band purchase
     */
    function setBand(
        uint16 bandId,
        uint256 price,
        uint16[] memory accessiblePools
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAmountNotZero(price) {
        // Checks: bandId must be in range
        if (bandId == 0 || bandId > s_totalBands) {
            revert Errors.Staking__InvalidBandId(bandId);
        }

        // Checks: amount must be in pool bounds
        if (accessiblePools.length > s_totalPools)
            revert Errors.Staking__MaximumLevelExceeded();

        // Effects: set band storage
        s_bandData[bandId] = Band({
            price: price,
            accessiblePools: accessiblePools
        });
        emit BandDataSet(bandId, price, accessiblePools);
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

    function getPool(uint16 poolId)
        external
        view
        returns (
            string memory name,
            uint48 distributionPercentage,
            uint48[] memory bandAllocationPercentage,
            uint256 usdtTokenAmount,
            uint256 usdcTokenAmount
        )
    {
        Pool storage pool = s_poolData[poolId];
        name = pool.name;
        distributionPercentage = pool.distributionPercentage;
        bandAllocationPercentage = pool.bandAllocationPercentage;
        usdtTokenAmount = pool.totalUsdtPoolTokenAmount;
        usdcTokenAmount = pool.totalUsdcPoolTokenAmount;
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
                              INTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _getStakingHash(
        address staker,
        uint16 bandLevel
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(staker, bandLevel));
    }
}
