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
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    uint128 public constant DECIMALS = 10 ** 6;
    uint128 public constant MONTH = 30 days;

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal s_usdtToken; // Token to be payed as reward
    IERC20 internal s_usdcToken; // Token to be payed as reward
    IERC20 internal s_wowToken; // Token to be staked

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    // @Enumerable mapping equivalent:
    // mapping(bytes32 hashedStakerAndBandLevel => uint256 lastestId)
    // @returns 0 or 1 as true or false values to determine staker band state
    mapping(bytes32 stakerAndBandLevel => EnumerableMap.Bytes32ToUintMap)
        internal s_stakerBandState;
    mapping(bytes32 stakerAndBandLevel => uint256 bandId) internal s_nextBandId;

    mapping(address poolId => Pool) internal s_poolData; // Pool data
    mapping(address bandId => Band) internal s_bandData; // Band data
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

    //NOTE: staking function base
    // function createPool(
    //     IERC20 _stakeToken
    // ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    //     Pool memory pool;
    //     pool.stakeToken = _stakeToken;
    //     pools.push(pool);
    //     uint256 poolId = pools.length - 1;
    //     emit PoolCreated(poolId);
    // }

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

    function _getStakingHash(
        address staker,
        uint16 bandLevel
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(staker, bandLevel));
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
