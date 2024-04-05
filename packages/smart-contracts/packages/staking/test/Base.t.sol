// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {IStaking} from "../contracts/interfaces/IStaking.sol";
import {StakingMock} from "./mocks/StakingMock.sol";
import {VestingMock} from "./mocks/VestingMock.sol";
import {TokenMock} from "./mocks/TokenMock.sol";
import {StakingConstants} from "./utils/StakingConstants.sol";
import {Events} from "./utils/Events.sol";

contract Base_Test is Test, StakingConstants, Events {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    address internal constant admin = address(0x1);
    address internal constant alice = address(0x2);
    address internal constant bob = address(0x3);
    address internal constant carol = address(0x4);
    address internal constant dan = address(0x5);
    address internal constant eve = address(0x6);

    address[] internal TEST_ACCOUNTS = [admin, alice, bob, carol, dan, eve];
    address[] internal STAKERS = [alice, bob, carol, dan, eve];
    address[] internal TWO_MINIMAL_STAKERS = [alice, bob];
    address[] internal THREE_MINIMAL_STAKERS = [alice, bob, carol];

    TokenMock internal usdtToken;
    TokenMock internal usdcToken;
    TokenMock internal wowToken;
    VestingMock internal vesting;
    StakingMock internal staking;

    /*//////////////////////////////////////////////////////////////////////////
                                  CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {}

    /*//////////////////////////////////////////////////////////////////////////
                                SET UP FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        vm.startPrank(admin);

        // USDT TOKEN
        usdtToken = new TokenMock();
        usdtToken.initialize(
            "USDT token",
            "USDT",
            USD_DECIMALS,
            INIT_TOKEN_SUPPLY
        );

        // USDC TOKEN
        usdcToken = new TokenMock();
        usdcToken.initialize(
            "USDC token",
            "USDTC",
            USD_DECIMALS,
            INIT_TOKEN_SUPPLY
        );

        // WOW TOKEN
        wowToken = new TokenMock();
        wowToken.initialize(
            "WOW token",
            "WOW",
            WOW_DECIMALS,
            INIT_TOKEN_SUPPLY
        );

        // VESTING CONTRACT
        vesting = new VestingMock();
        deal(address(vesting), INIT_ETH_BALANCE);
        wowToken.mint(address(vesting), INIT_TOKEN_BALANCE);

        // STAKING CONTRACT
        staking = new StakingMock();
        staking.initialize(
            usdtToken,
            usdcToken,
            wowToken,
            address(vesting),
            GELATO_EXECUTOR_ADDRESS,
            TOTAL_POOLS,
            TOTAL_BAND_LEVELS
        );

        // MINT TOKENS TO TEST ACCOUNTS
        uint8 accountsAmount = uint8(TEST_ACCOUNTS.length);
        for (uint8 i = 0; i < accountsAmount; ++i) {
            deal(TEST_ACCOUNTS[i], INIT_ETH_BALANCE);
            usdtToken.mint(TEST_ACCOUNTS[i], INIT_TOKEN_BALANCE);
            usdcToken.mint(TEST_ACCOUNTS[i], INIT_TOKEN_BALANCE);
            wowToken.mint(TEST_ACCOUNTS[i], INIT_TOKEN_BALANCE);
        }

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPER MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier stakeTokens(
        address _user,
        IStaking.StakingTypes _stakingType,
        uint16 _bandLevel,
        uint8 _month
    ) {
        _stakeTokens(_user, _stakingType, _bandLevel, _month, false);
        _;
    }

    modifier stakeVestedTokens(
        address _user,
        IStaking.StakingTypes _stakingType,
        uint16 _bandLevel,
        uint8 _month
    ) {
        _stakeTokens(_user, _stakingType, _bandLevel, _month, true);
        _;
    }

    modifier setBandLevelData() {
        _setBandLevelData();
        _;
    }

    modifier setSharesInMonth() {
        _setSharesInMonth(SHARES_IN_MONTH);
        _;
    }

    modifier createDistribution(TokenMock _token) {
        _createDistribution(_token);
        _;
    }

    modifier distributeRewards(TokenMock _token) {
        _distributeRewards(_token);
        _;
    }

    modifier setDistributionInProgress(bool _isInProgress) {
        _setDistributionInProgress(_isInProgress);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _setBandLevelData() internal {
        vm.startPrank(admin);

        for (uint16 i; i < TOTAL_BAND_LEVELS; i++) {
            staking.setBandLevel(
                BAND_LEVELS[i],
                BAND_PRICES[i],
                BAND_ACCESSIBLE_POOLS[i]
            );
        }

        vm.stopPrank();
    }

    function _setSharesInMonth(uint48[] memory _sharesInMonth) internal {
        vm.prank(admin);
        staking.setSharesInMonth(_sharesInMonth);
    }

    function _stakeTokens(
        address _user,
        IStaking.StakingTypes _stakingType,
        uint16 _bandLevel,
        uint8 _month,
        bool areTokensVested
    ) internal {
        if (areTokensVested) {
            vm.prank(address(vesting));
            staking.stakeVested(_user, _stakingType, _bandLevel, _month);
        } else {
            (uint256 price, ) = staking.getBandLevel(_bandLevel);

            vm.startPrank(_user);
            wowToken.approve(address(staking), price);
            staking.stake(_stakingType, _bandLevel, _month);
            vm.stopPrank();
        }
    }

    function _createDistribution(TokenMock _token) internal {
        vm.startPrank(admin);
        _token.approve(address(staking), DISTRIBUTION_AMOUNT);
        staking.createDistribution(_token, DISTRIBUTION_AMOUNT);
        vm.stopPrank();
    }

    function _distributeRewards(TokenMock _token) internal {
        vm.prank(admin);
        staking.distributeRewards(_token, STAKERS, DISTRIBUTION_REWARDS);
    }

    function _setDistributionInProgress(bool _isInProgress) internal {
        vm.prank(admin);
        staking.setDistributionInProgress(_isInProgress);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function assertEqStakingType(
        IStaking.StakingTypes stakingType,
        IStaking.StakingTypes expectedStakingType
    ) internal {
        assertEq(
            uint8(stakingType),
            uint8(expectedStakingType),
            "Invalid staking type"
        );
    }
}
