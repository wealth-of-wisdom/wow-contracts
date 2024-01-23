// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract NftSale_UpdateNf_Unit_Test is Unit_Test {
    address[] internal genesisUser = [alice];
    uint16[] internal genesisLevel = [LEVEL_2];
    uint256 internal upgradePrice;

    function setUp() public override {
        Unit_Test.setUp();

        _setNftLevels();

        uint256 level2Price = nft.getLevelData(LEVEL_2, false).price;
        uint256 level3Price = nft.getLevelData(LEVEL_3, false).price;
        upgradePrice = level3Price - level2Price;
    }

    function test_updateNftData_RevertIf_LevelIsZero() external {
        uint16 fakeLevel = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InvalidLevel.selector,
                fakeLevel
            )
        );
        vm.prank(admin);
        sale.updateNft(NFT_TOKEN_ID_0, fakeLevel, tokenUSDT);
    }

    function test_updateNftData_RevertIf_LevelIsTooHigh() external {
        uint16 fakeLevel = MAX_LEVEL + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InvalidLevel.selector,
                fakeLevel
            )
        );
        vm.prank(admin);
        sale.updateNft(NFT_TOKEN_ID_0, fakeLevel, tokenUSDT);
    }

    function test_updateNftData_RevertIf_NonExistantPayment() external {
        vm.expectRevert(Errors.NftSale__NonExistantPayment.selector);
        vm.prank(admin);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, IERC20(makeAddr("FakeToken")));
    }

    function test_updateNftData_RevertIf_TokenIsZeroAddress() external {
        vm.expectRevert(Errors.NftSale__NonExistantPayment.selector);
        vm.prank(admin);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, IERC20(ZERO_ADDRESS));
    }

    function test_updateNftData_RevertIf_NotNftDataOwner()
        external
        mintLevel2NftForAlice
    {
        vm.expectRevert(Errors.NftSale__NotNftOwner.selector);
        vm.prank(bob);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
    }

    function test_updateNftData_RevertIf_NftIsGenesis() external {
        vm.prank(admin);
        sale.mintGenesisNfts(genesisUser, genesisLevel);

        vm.expectRevert(Errors.NftSale__UnupdatableNft.selector);
        vm.prank(alice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
    }

    function test_updateNftData_RevertIf_NftIsDeactivated()
        external
        mintLevel2NftForAlice
    {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.expectRevert(Errors.NftSale__UnupdatableNft.selector);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();
    }

    function test_updateNftData_RevertIf_NftIsActiveButDurationPassed()
        external
        mintLevel2NftForAlice
    {
        vm.startPrank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0);

        skip(LEVEL_2_LIFECYCLE_DURATION);
        tokenUSDT.approve(address(sale), upgradePrice);

        vm.expectRevert(Errors.NftSale__UnupdatableNft.selector);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();
    }

    function test_updateNftData_RevertIf_NewLevelIsTheSame()
        external
        mintLevel2NftForAlice
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

    function test_updateNftData_RevertIf_NewLevelIsSmaller()
        external
        mintLevel2NftForAlice
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

    function test_updateNftData_TransfersTokensFromMsgSender()
        external
        mintLevel2NftForAlice
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
        mintLevel2NftForAlice
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

    function test_updateNftData_ChangesOldNftActivityType()
        external
        mintLevel2NftForAlice
    {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();

        INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_0);

        assertEq(
            uint8(nftData.activityType),
            uint8(NFT_DEACTIVATED),
            "NftData not deactivated"
        );
    }

    function test_updateNftData_DoesNotChangeOldNftData()
        external
        mintLevel2NftForAlice
    {
        vm.startPrank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();

        INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_0);
        uint256 expectedEndDate = block.timestamp + LEVEL_2_LIFECYCLE_DURATION;
        uint256 expectedExtendedEndDate = block.timestamp +
            LEVEL_2_LIFECYCLE_DURATION +
            LEVEL_2_EXTENSION_DURATION;

        assertEq(nftData.level, LEVEL_2, "NftData level set incorrectly");
        assertFalse(nftData.isGenesis, "NftData set as genesis");
        assertEq(
            nftData.activityEndTimestamp,
            expectedEndDate,
            "NftData activity end timestamp not set correctly"
        );
        assertEq(
            nftData.extendedActivityEndTimestamp,
            expectedExtendedEndDate,
            "NftData extended activity end timestamp not set correctly"
        );
    }

    function test_updateNftData_CreatesNewNftData()
        external
        mintLevel2NftForAlice
    {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();

        INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_1);

        assertEq(nftData.level, LEVEL_3, "NftData level set incorrectly");
        assertFalse(nftData.isGenesis, "NftData set as genesis");
        assertEq(
            uint8(nftData.activityType),
            uint8(NFT_NOT_ACTIVATED),
            "NftData not deactivated"
        );
        assertEq(
            nftData.activityEndTimestamp,
            0,
            "NftData activity end timestamp not set correctly"
        );
        assertEq(
            nftData.extendedActivityEndTimestamp,
            0,
            "NftData extended activity end timestamp not set correctly"
        );
    }

    function test_updateNftData_MintsNewNft() external mintLevel2NftForAlice {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 2, "User did not receive nft");
        assertEq(
            nft.ownerOf(NFT_TOKEN_ID_0),
            alice,
            "NFT not minted to correct address"
        );
        assertEq(
            nft.ownerOf(NFT_TOKEN_ID_1),
            alice,
            "NFT not minted to correct address"
        );
        assertEq(
            nft.getNextTokenId(),
            NFT_TOKEN_ID_2,
            "Token was not minted and ID not changed"
        );
    }

    function test_updateNftData_EmitsPurchasePaidEvent()
        external
        mintLevel2NftForAlice
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
        mintLevel2NftForAlice
    {
        vm.prank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);

        vm.expectEmit(true, true, true, true);
        emit NftUpdated(alice, NFT_TOKEN_ID_0, LEVEL_2, LEVEL_3);

        vm.prank(alice);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
    }
}
