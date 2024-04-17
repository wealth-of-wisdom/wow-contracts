// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IVesting, IVestingEvents} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {INft, INftEvents} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_ActivateNftData_Unit_Test is Unit_Test, IVestingEvents {
    function test_activateNftData_RevertIf_NotNftDataOwner()
        external
        mintLevel2NftForAlice
    {
        vm.expectRevert(Errors.Nft__NotNftOwner.selector);
        vm.prank(bob);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
    }

    function test_activateNftData_RevertIf_NftDataAlreadyActivated()
        external
        mintLevel2NftForAlice
    {
        vm.startPrank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        vm.expectRevert(Errors.Nft__AlreadyActivated.selector);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        vm.stopPrank();
    }

    function test_activateNftData_RevertIf_AlreadyDeactivated()
        external
        mintLevel2NftForAlice
        mintLevel2NftForAlice
    {
        vm.startPrank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        nft.activateNftData(NFT_TOKEN_ID_1, true);

        vm.expectRevert(Errors.Nft__AlreadyActivated.selector);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        vm.stopPrank();
    }

    function test_activateNftData_DeactivatesOldNft()
        external
        mintLevel2NftForAlice
        mintLevel2NftForAlice
    {
        vm.startPrank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        vm.stopPrank();

        INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_0);
        assertEq(
            uint8(nftData.activityType),
            uint8(NFT_DEACTIVATED),
            "NftData was not deactivated"
        );
    }

    function test_activateNftData_UpdatesActiveNftIdOnce()
        external
        mintLevel2NftForAlice
    {
        vm.prank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);

        assertEq(
            nft.getActiveNft(alice),
            NFT_TOKEN_ID_0,
            "Active NFT ID is incorrect"
        );
    }

    function test_activateNftData_UpdatesActiveNftIdTwice()
        external
        mintLevel2NftForAlice
        mintLevel2NftForAlice
    {
        vm.startPrank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        vm.stopPrank();

        assertEq(
            nft.getActiveNft(alice),
            NFT_TOKEN_ID_1,
            "Active NFT ID is incorrect"
        );
    }

    function test_activateNftData_UpdatesNftDataActivity()
        external
        mintLevel2NftForAlice
    {
        vm.prank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);

        INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_0);

        assertFalse(nftData.isGenesis, "Token genesis state changed");
        assertEq(nftData.level, LEVEL_2, "Level data changed");
        assertEq(
            uint8(nftData.activityType),
            uint8(NFT_ACTIVATION_TRIGGERED),
            "NftData was not activated"
        );
    }

    function test_activateNftData_UpdatesTimestamps()
        external
        mintLevel2NftForAlice
    {
        uint256 expectedEndTimestamp = block.timestamp +
            LEVEL_2_LIFECYCLE_DURATION;
        uint256 expectedExtensionEndTimestamp = expectedEndTimestamp +
            LEVEL_2_EXTENSION_DURATION;

        vm.prank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);

        INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_0);

        assertEq(
            nftData.activityEndTimestamp,
            expectedEndTimestamp,
            "Activity end timestamp is incorrect"
        );
        assertEq(
            nftData.extendedActivityEndTimestamp,
            expectedExtensionEndTimestamp,
            "Extended activity end timestamp is incorrect"
        );
    }

    function test_activateNftData_DoesNotAddBeneficiaryIfAllTokensAreDedicated()
        external
        mintLevel2NftForAlice
    {
        // Simulate: Vesting Pool has 0 tokens left to dedicate
        vesting.mock_setDedicatedAmount(
            DEFAULT_VESTING_PID,
            TOTAL_POOL_TOKEN_AMOUNT
        );

        vm.prank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            DEFAULT_VESTING_PID,
            alice
        );

        assertEq(
            beneficiary.totalTokenAmount,
            0,
            "Locked tokens amount is incorrect"
        );
    }

    function test_activateNftData_DoesNotAddBeneficiaryInVestingIfFlagWasDisabled()
        external
        mintLevel2NftForAlice
    {
        vm.prank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, false);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            DEFAULT_VESTING_PID,
            alice
        );

        assertEq(
            beneficiary.totalTokenAmount,
            0,
            "Locked tokens amount is incorrect"
        );
    }

    function test_activateNftData_DoesNotAddBeneficiaryInVestingIfFlagWasDisabledTwice()
        external
        mintLevel2NftForAlice
        mintLevel2NftForAlice
    {
        vm.startPrank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, false);
        nft.activateNftData(NFT_TOKEN_ID_1, false);
        vm.stopPrank();

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            DEFAULT_VESTING_PID,
            alice
        );

        assertEq(
            beneficiary.totalTokenAmount,
            0,
            "Locked tokens amount is incorrect"
        );
    }

    function test_activateNftData_AddsBeneficiaryInVestingWithFullRewardsAmount()
        external
        mintLevel2NftForAlice
    {
        vm.prank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            DEFAULT_VESTING_PID,
            alice
        );
        uint256 vestingRewards = nft
            .getLevelData(LEVEL_2, false)
            .vestingRewardWOWTokens;

        assertEq(
            beneficiary.totalTokenAmount,
            vestingRewards,
            "Locked tokens amount is incorrect"
        );
    }

    function test_activateNftData_AddsBeneficiaryInVestingWithPartialRewardsAmount()
        external
        mintLevel2NftForAlice
    {
        uint256 undedicatedAmount = nft
            .getLevelData(LEVEL_2, false)
            .vestingRewardWOWTokens / 2;

        // Simulate: Vesting Pool has 0 tokens left to dedicate
        vesting.mock_setDedicatedAmount(
            DEFAULT_VESTING_PID,
            TOTAL_POOL_TOKEN_AMOUNT - undedicatedAmount
        );

        vm.prank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            DEFAULT_VESTING_PID,
            alice
        );

        assertEq(
            beneficiary.totalTokenAmount,
            undedicatedAmount,
            "Locked tokens amount is incorrect"
        );
    }

    function test_activateNftData_RevertIf_VestingContractIsInvalid()
        external
        mintLevel2NftForAlice
    {
        vm.prank(admin);
        nft.setVestingContract(IVesting(makeAddr("newVesting")));

        vm.expectRevert();
        vm.prank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
    }

    function test_activateNftData_EmitsBeneficiaryAddedEvent()
        external
        mintLevel2NftForAlice
    {
        vm.expectEmit(true, true, true, true);
        emit BeneficiaryAdded(
            DEFAULT_VESTING_PID,
            alice,
            nft.getLevelData(LEVEL_2, false).vestingRewardWOWTokens
        );

        vm.prank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
    }

    function test_activateNftData_EmitsNftDataActivatedEvent()
        external
        mintLevel2NftForAlice
    {
        uint256 activityEndTimestamp = block.timestamp +
            LEVEL_2_LIFECYCLE_DURATION;
        uint256 extendedActivityEndTimestamp = activityEndTimestamp +
            LEVEL_2_EXTENSION_DURATION;
        vm.expectEmit(true, true, true, true);
        emit NftDataActivated(
            alice,
            NFT_TOKEN_ID_0,
            LEVEL_2,
            false,
            activityEndTimestamp,
            extendedActivityEndTimestamp
        );

        vm.prank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
    }
}
