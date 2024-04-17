// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_SetTokenURI_Unit_Test is Unit_Test {
    string internal newTokenURI = "https://random.com/0.json";

    function test_setTokenURI_RevertIf_SenderIsNotDefaultAdmin()
        external
        mintLevel2NftForAlice
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        nft.setTokenURI(NFT_TOKEN_ID_0, newTokenURI);
    }

    function test_setTokenURI_UpdatesURIOnce() external mintLevel2NftForAlice {
        vm.prank(admin);
        nft.setTokenURI(NFT_TOKEN_ID_0, newTokenURI);

        assertEq(nft.tokenURI(NFT_TOKEN_ID_0), newTokenURI);
    }

    function test_setTokenURI_UpdatesURITwice() external mintLevel2NftForAlice {
        vm.startPrank(admin);
        nft.setTokenURI(NFT_TOKEN_ID_0, "-");
        nft.setTokenURI(NFT_TOKEN_ID_0, newTokenURI);
        vm.stopPrank();

        assertEq(nft.tokenURI(NFT_TOKEN_ID_0), newTokenURI);
    }
}
