// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.20;

// import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
// import {Errors} from "../../../contracts/libraries/Errors.sol";
// import {WOW_Vesting_Unit_Test} from "./WowVestingUnit.t.sol";

// contract Vesting_Claim_Unit_Test is WOW_Vesting_Unit_Test {
//     function setUp() public override {
//         WOW_Vesting_Unit_Test.setUp();
//         token.mint(address(vesting), INIT_TOKEN_BALANCE);
//     }

//     /*//////////////////////////////////////////////////////////////////////////////
//                                     HELPER MODIFIERS
//     //////////////////////////////////////////////////////////////////////////////*/

//     modifier addVestingPool() {
//         _addDefaultVestingPool();
//         _;
//     }

//     /*//////////////////////////////////////////////////////////////////////////////
//                                         TESTS
//     //////////////////////////////////////////////////////////////////////////////*/

//     function test_claimTokens_RevertIf_PoolDoesNotExist() external {
//         vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
//         vesting.claimTokens(PRIMARY_POOL);
//     }

//     function test_claimTokens_RevertIf_SenderIsZeroAddress()
//         external
//         addVestingPool
//     {
//         vm.expectRevert(Errors.Vesting__ZeroAddress.selector);
//         vm.prank(ZERO_ADDRESS);
//         vesting.claimTokens(PRIMARY_POOL);
//     }

//     function test_claimTokens_ReverIf_NotBeneficiary() external addVestingPool {
//         vm.expectRevert(Errors.Vesting__NotBeneficiary.selector);
//         vesting.claimTokens(PRIMARY_POOL);
//     }

//     function test_claimTokens_RevertIf_NoTokensUnlocked()
//         external
//         addVestingPool
//     {
//         vesting.addBeneficiary(
//             PRIMARY_POOL,
//             alice,
//             BENEFICIARY_TOKEN_AMOUNT
//         );

//         vm.expectRevert(Errors.Vesting__NoTokensUnlocked.selector);
//         vm.prank(alice);
//         vesting.claimTokens(PRIMARY_POOL);
//     }

//     function test_claimTokens_RevertIf_NotEnoughTokenBalance()
//         external
//         addVestingPool
//     {
//         // skip(1 hours);
//         // vesting.addBeneficiary(
//         //     PRIMARY_POOL,
//         //     alice,
//         //     BENEFICIARY_TOKEN_AMOUNT
//         // );
//         // vm.expectRevert(Errors.Vesting__NoTokensUnlocked.selector);
//         // vesting.claimTokens(PRIMARY_POOL);
//     }

//     function test_claimTokens_RevertIf_StakedTokens() external addVestingPool {}

//     function test_claimTokens_IncreasesClaimedTokensAmount()
//         external
//         addVestingPool
//     {}

//     function test_claimTokens_TransfersTokensToSender()
//         external
//         addVestingPool
//     {}

//     function test_claimTokens_TransfersTokensFromVesting()
//         external
//         addVestingPool
//     {}

//     function test_claimTokens_EmitsTokensClaimedEvent()
//         external
//         addVestingPool
//     {}
// }
