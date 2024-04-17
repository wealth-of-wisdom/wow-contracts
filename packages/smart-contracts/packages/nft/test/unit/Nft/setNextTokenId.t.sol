// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_SetNextTokenId_Unit_Test is Unit_Test {
    string internal newTokenURI = "https://random.com/0.json";

    function test_setNextTokenId_RevertIf_SenderIsNotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        nft.setNextTokenId(NFT_TOKEN_ID_1);
    }

    function test_setNextTokenId_SetsNewTokenIdCorrectly()
        external
        mintLevel2NftForAlice
    {
        assertEq(nft.getNextTokenId(), NFT_TOKEN_ID_1);

        vm.prank(admin);
        nft.setNextTokenId(NFT_TOKEN_ID_0);

        assertEq(nft.getNextTokenId(), NFT_TOKEN_ID_0);
    }

    function test_setNextTokenId_EmitsNextTokenIdSetEvent()
        external
        mintLevel2NftForAlice
    {
        vm.expectEmit(address(nft));
        emit NextTokenIdSet(NFT_TOKEN_ID_0);

        vm.prank(admin);
        nft.setNextTokenId(NFT_TOKEN_ID_0);
    }
}
