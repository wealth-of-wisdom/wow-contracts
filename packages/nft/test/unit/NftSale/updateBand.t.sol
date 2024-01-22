// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {INft} from "@wealth-of-wisdom/nft/contracts/interfaces/INft.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {Nft_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftUnit.t.sol";

contract NftSale_UpdateNftData_Unit_Test is Nft_Unit_Test {
    uint256 internal upgradePrice;
    address[] genesisUser = [alice];
    uint16[] lvl = [LEVEL_2];

    function setUp() public override {
        Nft_Unit_Test.setUp();

        uint256 newPrice = nftContract.getLevelData(LEVEL_1).price;
        uint256 oldPrice = nftContract.getLevelData(LEVEL_2).price;
        upgradePrice = newPrice - oldPrice;
    }

    function test_updateNftData_RevertIf_InvalidLevel()
        external
        mintLevel2NftDataForAlice
    {
        uint16 fakeLevel = 16;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InvalidLevel.selector,
                fakeLevel
            )
        );
        vm.prank(admin);
        sale.updateNft(NFT_TOKEN_ID_0, fakeLevel, tokenUSDT);
    }

    function test_updateNftData_RevertIf_NonExistantPayment()
        external
        mintLevel2NftDataForAlice
    {
        vm.expectRevert(Errors.NftSale__NonExistantPayment.selector);
        vm.prank(admin);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, IERC20(makeAddr("FakeToken")));
    }

    function test_updateNftData_RevertIf_TokenIsZeroAddress() external {
        vm.expectRevert(Errors.NftSale__NonExistantPayment.selector);
        vm.prank(admin);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, IERC20(ZERO_ADDRESS));
    }

    function test_updateNftData_RevertIf_NotNftDataOwner()
        external
        mintLevel2NftDataForAlice
    {
        vm.expectRevert(Errors.NftSale__NotNftOwner.selector);
        vm.prank(bob);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, tokenUSDT);
    }

    function test_updateNftData_RevertIf_UnupdatableNftDataIsGenesis()
        external
    {
        vm.prank(admin);
        sale.mintGenesisNfts(genesisUser, lvl);

        vm.startPrank(alice);
        vm.expectRevert(Errors.NftSale__UnupdatableNft.selector);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, tokenUSDT);
        vm.stopPrank();
    }

    function test_updateNftData_RevertIf_UnupdatableNftDataIsDisabled()
        external
        mintLevel2NftDataForAlice
    {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.expectRevert(Errors.NftSale__UnupdatableNft.selector);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, tokenUSDT);
        vm.stopPrank();
    }

    function test_updateNftData_RevertIf_NewLevelIsTheSame()
        external
        mintLevel2NftDataForAlice
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InvalidLevel.selector,
                LEVEL_2
            )
        );
        vm.prank(alice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, tokenUSDT);
    }

    function test_updateNftData_RevertIf_NewLevelIsTheSmaller()
        external
        mintLevel2NftDataForAlice
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InvalidLevel.selector,
                LEVEL_1
            )
        );
        vm.prank(alice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_1, tokenUSDT);
    }

    function test_updateNftData_ChangesOldNftActivityTypeOnly()
        external
        mintLevel2NftDataForAlice
    {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();

        INft.NftData memory nftData = nftContract.getNftData(NFT_TOKEN_ID_0);

        assertEq(nftData.level, LEVEL_2, "NftData level set incorrectly");
        assertFalse(nftData.isGenesis, "NftData set as genesis");
        assertEq(
            uint8(nftData.activityType),
            uint8(NFT_ACTIVITY_TYPE_DEACTIVATED),
            "NftData not deactivated"
        );
    }

    function test_updateNftData_CreatesNewNftData()
        external
        mintLevel2NftDataForAlice
    {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();

        INft.NftData memory nftData = nftContract.getNftData(NFT_TOKEN_ID_1);

        assertEq(nftData.level, LEVEL_3, "NftData level set incorrectly");
        assertFalse(nftData.isGenesis, "NftData set as genesis");
        assertEq(
            uint8(nftData.activityType),
            uint8(NFT_ACTIVITY_TYPE_NOT_ACTIVATED),
            "NftData not deactivated"
        );
    }

    function test_updateNftData_TransfersTokensFromMsgSender()
        external
        mintLevel2NftDataForAlice
    {
        uint256 startingAliceBalance = tokenUSDT.balanceOf(alice);

        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();

        uint256 endingAliceBalance = tokenUSDT.balanceOf(alice);

        assertEq(
            startingAliceBalance - upgradePrice,
            endingAliceBalance,
            "Tokens not transferred"
        );
    }

    function test_updateNftData_TransfersTokensToContract()
        external
        mintLevel2NftDataForAlice
    {
        uint256 startingContractBalance = tokenUSDT.balanceOf(address(sale));

        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();

        uint256 endingContractBalance = tokenUSDT.balanceOf(address(sale));

        assertEq(
            startingContractBalance + upgradePrice,
            endingContractBalance,
            "Tokens not transferred"
        );
    }

    function test_updateNftData_MintsNewNft()
        external
        mintLevel2NftDataForAlice
    {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();

        assertEq(nftContract.balanceOf(alice), 2, "User did not receive nft");
        assertEq(
            nftContract.ownerOf(NFT_TOKEN_ID_0),
            alice,
            "NFT not minted to correct address"
        );
        assertEq(
            nftContract.ownerOf(NFT_TOKEN_ID_1),
            alice,
            "NFT not minted to correct address"
        );
        assertEq(
            nftContract.getNextTokenId(),
            NFT_TOKEN_ID_2,
            "Token was not minted and ID not changed"
        );
    }

    function test_updateNftData_EmitsPurchasePaidEvent()
        external
        mintLevel2NftDataForAlice
    {
        vm.prank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);

        vm.expectEmit(true, true, true, true);
        emit PurchasePaid(tokenUSDT, upgradePrice);

        vm.prank(alice);
        sale.mintNft(LEVEL_2, tokenUSDT);
    }

    function test_updateNftData_EmitsNftDataUpdated()
        external
        mintLevel2NftDataForAlice
    {
        vm.prank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);

        vm.expectEmit(true, true, true, true);
        emit NftUpdated(alice, NFT_TOKEN_ID_0, LEVEL_2, LEVEL_3);

        vm.prank(alice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
    }
}
