// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {Nft_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftUnit.t.sol";

contract Nft_TransferFrom_Unit_Test is Nft_Unit_Test {
    function setUp() public override {
        Nft_Unit_Test.setUp();

        vm.prank(admin);
        nftContract.safeMint(alice, LEVEL_1, false);
    }

    function test_transferFrom_RevertIf_NotWhitelistedSender() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                WHITELISTED_SENDER_ROLE
            )
        );
        vm.prank(alice);
        nftContract.transferFrom(alice, bob, NFT_TOKEN_ID_0);
    }

    function test_transferFrom_TransfersNftSuccessfully() external {
        assertEq(nftContract.balanceOf(alice), 1, "NFT not minted to alice");
        assertEq(nftContract.balanceOf(bob), 0, "NFT minted to bob");

        vm.prank(admin);
        nftContract.grantRole(WHITELISTED_SENDER_ROLE, alice);

        vm.prank(alice);
        nftContract.transferFrom(alice, bob, NFT_TOKEN_ID_0);

        assertEq(
            nftContract.balanceOf(alice),
            0,
            "NFT not transferred from alice"
        );
        assertEq(nftContract.balanceOf(bob), 1, "NFT not transferred to bob");
    }
}
