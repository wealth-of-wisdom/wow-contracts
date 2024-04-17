// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract NftSale_MintGenesisNft_Unit_Test is Unit_Test {
    address[] singleUserArray = [alice];
    address[] threeUsersArray = [alice, bob, carol];
    address[] zeroAddressArray = [ZERO_ADDRESS];

    uint16[] singleLevelArray = [LEVEL_2];
    uint16[] threeLevelsArray = [LEVEL_1, LEVEL_2, LEVEL_3];

    /* /////////////////////////////////////////////////////////////////////////
                                    ASSERTION HELPERS
    ////////////////////////////////////////////////////////////////////////// */

    function assertGenesisNft(
        INft.NftData memory nftData,
        uint16 level
    ) internal {
        assertEq(nftData.level, level, "Nft level set incorrectly");
        assertEq(
            uint8(nftData.activityType),
            uint8(NFT_ACTIVATION_TRIGGERED),
            "Nft not activated"
        );
        assertTrue(nftData.isGenesis, "Nft not set as genesis");
    }

    /* /////////////////////////////////////////////////////////////////////////
                                        TESTS
    ////////////////////////////////////////////////////////////////////////// */

    function test_mintGenesisNft_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        sale.mintGenesisNfts(singleUserArray, singleLevelArray);
    }

    function test_mintGenesisNft_RevertIf_ArrayLengthsDoNotMatch() external {
        vm.expectRevert(Errors.NftSale__MismatchInVariableLength.selector);
        vm.prank(admin);
        sale.mintGenesisNfts(singleUserArray, threeLevelsArray);
    }

    function test_mintGenesisNft_RevertIf_ReceiverIsZeroAddress() external {
        vm.expectRevert(Errors.Nft__ZeroAddress.selector);
        vm.prank(admin);
        sale.mintGenesisNfts(zeroAddressArray, singleLevelArray);
    }

    function test_mintGenesisNft_Creates1NewNft() external {
        vm.prank(admin);
        sale.mintGenesisNfts(singleUserArray, singleLevelArray);

        INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_0);
        assertGenesisNft(nftData, LEVEL_2);
    }

    function test_mintGenesisNft_Creates3NewNfts() external {
        vm.prank(admin);
        sale.mintGenesisNfts(threeUsersArray, threeLevelsArray);

        assertGenesisNft(nft.getNftData(NFT_TOKEN_ID_0), LEVEL_1);
        assertGenesisNft(nft.getNftData(NFT_TOKEN_ID_1), LEVEL_2);
        assertGenesisNft(nft.getNftData(NFT_TOKEN_ID_2), LEVEL_3);
    }

    function test_mintGenesisNft_Mints1Nft() external {
        vm.prank(admin);
        sale.mintGenesisNfts(singleUserArray, singleLevelArray);

        assertEq(nft.getNextTokenId(), NFT_TOKEN_ID_1, "Token id incorrect");
        assertEq(nft.balanceOf(alice), 1, "User did not receive nft");
        assertEq(nft.ownerOf(NFT_TOKEN_ID_0), alice, "Not the owner");
    }

    function test_mintGenesisNft_Mints3Nft() external {
        vm.prank(admin);
        sale.mintGenesisNfts(threeUsersArray, threeLevelsArray);

        assertEq(nft.getNextTokenId(), 3, "Token id incorrect");
        assertEq(nft.balanceOf(alice), 1, "Alice did not receive nft");
        assertEq(nft.balanceOf(bob), 1, "Bob did not receive nft");
        assertEq(nft.balanceOf(carol), 1, "Carol did not receive nft");
        assertEq(nft.ownerOf(NFT_TOKEN_ID_0), alice, "Not the owner");
        assertEq(nft.ownerOf(NFT_TOKEN_ID_1), bob, "Not the owner");
        assertEq(nft.ownerOf(NFT_TOKEN_ID_2), carol, "Not the owner");
    }

    function test_mintGenesisNft_EmitsNftMintedEvent3Times() external {
        vm.expectEmit(address(sale));
        emit NftMinted(alice, LEVEL_1, true, 0);

        vm.expectEmit(address(sale));
        emit NftMinted(bob, LEVEL_2, true, 0);

        vm.expectEmit(address(sale));
        emit NftMinted(carol, LEVEL_3, true, 0);

        vm.prank(admin);
        sale.mintGenesisNfts(threeUsersArray, threeLevelsArray);
    }

    function test_mintGenesisNft_DoesNotLockTokensInVesting() external {
        vm.prank(admin);
        sale.mintGenesisNfts(singleUserArray, singleLevelArray);

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
}
