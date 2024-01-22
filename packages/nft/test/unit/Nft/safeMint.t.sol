// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {Nft_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftUnit.t.sol";

contract Nft_SafeMint_Unit_Test is Nft_Unit_Test {
    function test_safeMint_RevertIf_NotMinter() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                MINTER_ROLE
            )
        );
        vm.prank(alice);
        nftContract.safeMint(alice, LEVEL_1, false);
    }

    function test_safeMint_IncreasesNextTokenIdBy1() external {
        assertEq(nftContract.getNextTokenId(), 0, "Next token ID not 0");

        vm.prank(admin);
        nftContract.safeMint(alice, LEVEL_1, false);

        assertEq(nftContract.getNextTokenId(), 1, "Next token ID not 1");
    }

    function test_safeMint_IncreasesNextTokenIdBy5() external {
        assertEq(nftContract.getNextTokenId(), 0, "Next token ID not 0");

        vm.startPrank(admin);
        nftContract.safeMint(alice, LEVEL_1, false);
        nftContract.safeMint(bob, LEVEL_1, false);
        nftContract.safeMint(alice, LEVEL_1, false);
        nftContract.safeMint(bob, LEVEL_1, false);
        nftContract.safeMint(alice, LEVEL_1, false);
        vm.stopPrank();

        assertEq(nftContract.getNextTokenId(), 5, "Next token ID not 5");
    }

    function test_safeMint_Mints1TokenWithId0() external {
        vm.prank(admin);
        nftContract.safeMint(alice, LEVEL_1, false);

        assertEq(nftContract.ownerOf(NFT_TOKEN_ID_0), alice, "NFT not minted");
        assertEq(
            nftContract.balanceOf(alice),
            1,
            "NFT minted to incorrect address"
        );
    }

    function test_safeMint_Mints5Tokens() external {
        vm.startPrank(admin);
        nftContract.safeMint(alice, LEVEL_1, false);
        nftContract.safeMint(bob, LEVEL_1, false);
        nftContract.safeMint(alice, LEVEL_1, false);
        nftContract.safeMint(bob, LEVEL_1, false);
        nftContract.safeMint(alice, LEVEL_1, false);
        vm.stopPrank();

        assertEq(nftContract.ownerOf(NFT_TOKEN_ID_0), alice, "NFT not minted");
        assertEq(nftContract.ownerOf(NFT_TOKEN_ID_1), bob, "NFT not minted");
        assertEq(nftContract.ownerOf(NFT_TOKEN_ID_2), alice, "NFT not minted");
        assertEq(nftContract.ownerOf(3), bob, "NFT not minted");
        assertEq(nftContract.ownerOf(4), alice, "NFT not minted");
        assertEq(
            nftContract.balanceOf(alice),
            3,
            "NFT minted to incorrect address"
        );
        assertEq(
            nftContract.balanceOf(bob),
            2,
            "NFT minted to incorrect address"
        );
    }
}
