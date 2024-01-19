// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IVesting, IVestingEvents} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {INft, INftEvents} from "@wealth-of-wisdom/nft/contracts/interfaces/INft.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {Nft_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftUnit.t.sol";

contract Nft_ActivateNftData_Unit_Test is
    Nft_Unit_Test,
    IVestingEvents,
    INftEvents
{
    function test_activateNftData_RevertIf_NotNftDataOwner()
        external
        mintLevel2NftDataForAlice
    {
        vm.expectRevert(Errors.Nft__NotNftOwner.selector);
        vm.prank(bob);
        nftContract.activateNftData(NFT_TOKEN_ID_0);
    }

    function test_activateNftData_RevertIf_NftDataAlreadyActivated()
        external
        setNftDataForContract
        mintLevel2NftDataForAlice
    {
        vm.startPrank(alice);
        nftContract.activateNftData(NFT_TOKEN_ID_0);
        vm.expectRevert(Errors.Nft__AlreadyActivated.selector);
        nftContract.activateNftData(NFT_TOKEN_ID_0);
        vm.stopPrank();
    }

    function test_activateNftData_UpdatesNftDataActivity()
        external
        setNftDataForContract
        mintLevel2NftDataForAlice
    {
        vm.prank(alice);
        nftContract.activateNftData(NFT_TOKEN_ID_0);

        INft.NftData memory nftData = nftContract.getNftData(NFT_TOKEN_ID_0);

        assertFalse(nftData.isGenesis, "Token genesis state changed");
        assertEq(nftData.level, LEVEL_2, "Level data changed");
        assertEq(
            uint8(nftData.activityType),
            uint8(NFT_ACTIVITY_TYPE_ACTIVATION_TRIGGERED),
            "NftData was not activated"
        );
    }

    function test_activateNftData_AddsBeneficiaryInVestingContract()
        external
        setNftDataForContract
        mintLevel2NftDataForAlice
    {
        vm.prank(alice);
        nftContract.activateNftData(NFT_TOKEN_ID_0);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            DEFAULT_VESTING_PID,
            alice
        );
        uint256 tokensInVesting = nftContract
            .getLevelData(LEVEL_2)
            .vestingRewardWOWTokens;

        assertEq(
            beneficiary.totalTokenAmount,
            tokensInVesting,
            "Locked tokens amount is incorrect"
        );
    }

    function test_activateNftData_EmitsBeneficiaryAddedEvent()
        external
        setNftDataForContract
        mintLevel2NftDataForAlice
    {
        vm.expectEmit(true, true, true, true);
        emit BeneficiaryAdded(
            DEFAULT_VESTING_PID,
            alice,
            nftContract.getLevelData(LEVEL_2).vestingRewardWOWTokens
        );

        vm.prank(alice);
        nftContract.activateNftData(NFT_TOKEN_ID_0);
    }

    function test_activateNftData_EmitsNftDataActivatedEvent()
        external
        setNftDataForContract
        mintLevel2NftDataForAlice
    {
        uint256 activityEndTimestamp = block.timestamp +
            LEVEL_2_LIFECYCLE_TIMESTAMP;
        uint256 extendedActivityEndTimestamp = activityEndTimestamp +
            LEVEL_2_EXTENDED_LIFECYCLE_TIMESTAMP;
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
        nftContract.activateNftData(NFT_TOKEN_ID_0);
    }
}
