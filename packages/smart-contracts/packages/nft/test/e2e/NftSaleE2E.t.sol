// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {INft} from "../../contracts/interfaces/INft.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";
import {NftMock} from "../mocks/NftMock.sol";
import {NftSaleMock} from "../mocks/NftSaleMock.sol";
import {VestingMock} from "../mocks/VestingMock.sol";
import {Base_Test} from "../Base.t.sol";

contract NftSale_E2E_Test is Base_Test {
    address[] internal singleReceiverArray = [alice];
    uint16[] internal singleLevelArray = [LEVEL_1];
    address[] internal threeReceiversArray = [alice, bob, carol];
    uint16[] internal threeLevelsArray = [LEVEL_1, LEVEL_2, LEVEL_3];
    uint8[5] internal zeroAmounts = [0, 0, 0, 0, 0];

    function setUp() public virtual override {
        Base_Test.setUp();

        vm.startPrank(admin);

        nft.grantRole(WHITELISTED_SENDER_ROLE, alice);
        nft.grantRole(WHITELISTED_SENDER_ROLE, bob);
        nft.grantRole(WHITELISTED_SENDER_ROLE, carol);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  ASSERTION HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function assertUserOwnedNfts(address user) internal {
        assertEq(nft.balanceOf(user), 0, "User owns NFT");
    }

    function assertUserOwnedNfts(
        address user,
        uint256[1] memory tokenIds
    ) internal {
        uint256[] memory tokenIdsArray = new uint256[](1);
        tokenIdsArray[0] = tokenIds[0];
        _assertUserOwnedNfts(user, tokenIdsArray);
    }

    function assertUserOwnedNfts(
        address user,
        uint256[2] memory tokenIds
    ) internal {
        uint256[] memory tokenIdsArray = new uint256[](2);
        tokenIdsArray[0] = tokenIds[0];
        tokenIdsArray[1] = tokenIds[1];
        _assertUserOwnedNfts(user, tokenIdsArray);
    }

    function assertUserOwnedNfts(
        address user,
        uint256[3] memory tokenIds
    ) internal {
        uint256[] memory tokenIdsArray = new uint256[](3);
        tokenIdsArray[0] = tokenIds[0];
        tokenIdsArray[1] = tokenIds[1];
        tokenIdsArray[2] = tokenIds[2];
        _assertUserOwnedNfts(user, tokenIdsArray);
    }

    function assertUserOwnedNfts(
        address user,
        uint256[4] memory tokenIds
    ) internal {
        uint256[] memory tokenIdsArray = new uint256[](4);
        tokenIdsArray[0] = tokenIds[0];
        tokenIdsArray[1] = tokenIds[1];
        tokenIdsArray[2] = tokenIds[2];
        tokenIdsArray[3] = tokenIds[3];
        _assertUserOwnedNfts(user, tokenIdsArray);
    }

    function _assertUserOwnedNfts(
        address user,
        uint256[] memory tokenIds
    ) internal {
        uint256 tokenIdsLength = tokenIds.length;

        assertEq(
            nft.balanceOf(user),
            tokenIdsLength,
            "User did not receive nft"
        );

        for (uint256 i; i < tokenIdsLength; i++) {
            assertEq(nft.ownerOf(tokenIds[i]), user, "Not owner");
        }
    }

    function assertNftData(
        uint256 tokenId,
        uint16 level,
        bool isGenesis,
        INft.ActivityType status,
        uint256 endDate,
        uint256 extendedEndDate
    ) internal {
        INft.NftData memory nftData = nft.getNftData(tokenId);

        assertEq(nftData.level, level, "NftData level set incorrectly");
        assertEq(nftData.isGenesis, isGenesis, "NftData set as genesis");
        assertEq(
            uint8(nftData.activityType),
            uint8(status),
            "NftData not deactivated"
        );
        assertEq(
            nftData.activityEndTimestamp,
            endDate,
            "NftData activity end timestamp not set correctly"
        );
        assertEq(
            nftData.extendedActivityEndTimestamp,
            extendedEndDate,
            "NftData extended activity end timestamp not set correctly"
        );
    }

    function assertTotalNftData(
        uint8[5] memory mainNftAmounts,
        uint8[5] memory genesisNftAmounts
    ) internal {
        assertEq(
            mainNftAmounts.length,
            MAX_LEVEL,
            "Incorrect number of levels"
        );
        assertEq(
            genesisNftAmounts.length,
            MAX_LEVEL,
            "Incorrect number of levels"
        );
        uint256 totalAmount;

        // MAIN NFTs
        for (uint16 i; i < MAX_LEVEL; i++) {
            totalAmount += mainNftAmounts[i];
            assertEq(
                nft.getLevelData(i + 1, false).nftAmount,
                mainNftAmounts[i],
                "Total NftData not set correctly"
            );
        }

        // GENESIS NFTs
        for (uint16 i; i < MAX_LEVEL; i++) {
            totalAmount += genesisNftAmounts[i];
            assertEq(
                nft.getLevelData(i + 1, true).nftAmount,
                genesisNftAmounts[i],
                "Total NftData not set correctly"
            );
        }

        assertEq(nft.getNextTokenId(), totalAmount, "Next token id incorrect");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_With2Users_Mint_Update_Activate_Transfer() external {
        /**
         * 1. Alice mints Nft level 1
         * 2. Alice updates Nft to level 2
         * 3. Alice activates Nft level 2
         * 4. Alice transfers Nft level 2 to Bob
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        nft.safeTransferFrom(alice, bob, NFT_TOKEN_ID_1);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(alice, [NFT_TOKEN_ID_0]);
        assertUserOwnedNfts(bob, [NFT_TOKEN_ID_1]);
        assertNftData(NFT_TOKEN_ID_0, LEVEL_1, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_1,
            LEVEL_2,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_2_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_2_FULL_EXTENDED_DURATION
        );
        assertTotalNftData([1, 1, 0, 0, 0], zeroAmounts);
    }

    function test_With2Users_Mint_Activate_Update_Transfer() external {
        /**
         * 1. Alice mints Nft level 1
         * 2. Alice activates Nft level 1
         * 3. Alice updates Nft to level 2
         * 4. Alice transfers Nft level 2 to Bob
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, tokenUSDT);
        nft.safeTransferFrom(alice, bob, NFT_TOKEN_ID_1);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(alice, [NFT_TOKEN_ID_0]);
        assertUserOwnedNfts(bob, [NFT_TOKEN_ID_1]);
        assertNftData(
            NFT_TOKEN_ID_0,
            LEVEL_1,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_1_FULL_EXTENDED_DURATION
        );
        assertNftData(NFT_TOKEN_ID_1, LEVEL_2, false, NFT_NOT_ACTIVATED, 0, 0);
        assertTotalNftData([1, 1, 0, 0, 0], zeroAmounts);
    }

    function test_With2Users_Mint_Activate_Update_Activate_Transfer() external {
        /**
         * 1. Alice mints Nft level 1
         * 2. Alice activates Nft level 1
         * 3. Alice updates Nft to level 2
         * 4. Alice activates Nft level 2
         * 5. Alice transfers Nft level 2 to Bob
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        nft.safeTransferFrom(alice, bob, NFT_TOKEN_ID_1);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(alice, [NFT_TOKEN_ID_0]);
        assertUserOwnedNfts(bob, [NFT_TOKEN_ID_1]);
        assertNftData(
            NFT_TOKEN_ID_0,
            LEVEL_1,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_1_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_1,
            LEVEL_2,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_2_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_2_FULL_EXTENDED_DURATION
        );
        assertTotalNftData([1, 1, 0, 0, 0], zeroAmounts);
    }

    function test_With2Users_Mint_Update5Times_Activate_Transfer() external {
        /**
         * 1. Alice mints Nft level 1
         * 2. Alice updates Nft to level 2
         * 3. Alice updates Nft to level 3
         * 4. Alice updates Nft to level 4
         * 5. Alice updates Nft to level 5
         * 6. Alice activates Nft level 5
         * 7. Alice transfers Nft level 5 to Bob
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_1, LEVEL_3, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_2, LEVEL_4, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_3, LEVEL_5, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_4, true);
        nft.safeTransferFrom(alice, bob, NFT_TOKEN_ID_4);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(
            alice,
            [NFT_TOKEN_ID_0, NFT_TOKEN_ID_1, NFT_TOKEN_ID_2, NFT_TOKEN_ID_3]
        );
        assertUserOwnedNfts(bob, [NFT_TOKEN_ID_4]);
        assertNftData(NFT_TOKEN_ID_0, LEVEL_1, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(NFT_TOKEN_ID_1, LEVEL_2, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(NFT_TOKEN_ID_2, LEVEL_3, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(NFT_TOKEN_ID_3, LEVEL_4, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_4,
            LEVEL_5,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_5_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_5_FULL_EXTENDED_DURATION
        );
        assertTotalNftData([1, 1, 1, 1, 1], zeroAmounts);
    }

    function test_With2Users_Mint_UpdateAndActivate5Time_Transfer() external {
        /**
         * 1. Alice mints Nft level 1
         * 2. Alice activates Nft level 1
         * 3. Alice updates Nft to level 2
         * 4. Alice activates Nft level 2
         * 5. Alice updates Nft to level 3
         * 6. Alice activates Nft level 3
         * 7. Alice updates Nft to level 4
         * 8. Alice activates Nft level 4
         * 9. Alice updates Nft to level 5
         * 10. Alice activates Nft level 5
         * 11. Alice transfers Nft level 5 to Bob
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        sale.updateNft(NFT_TOKEN_ID_1, LEVEL_3, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_2, true);
        sale.updateNft(NFT_TOKEN_ID_2, LEVEL_4, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_3, true);
        sale.updateNft(NFT_TOKEN_ID_3, LEVEL_5, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_4, true);
        nft.safeTransferFrom(alice, bob, NFT_TOKEN_ID_4);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(
            alice,
            [NFT_TOKEN_ID_0, NFT_TOKEN_ID_1, NFT_TOKEN_ID_2, NFT_TOKEN_ID_3]
        );
        assertUserOwnedNfts(bob, [NFT_TOKEN_ID_4]);
        assertNftData(
            NFT_TOKEN_ID_0,
            LEVEL_1,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_1_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_1,
            LEVEL_2,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_2_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_2_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_2,
            LEVEL_3,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_3_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_3_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_3,
            LEVEL_4,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_4_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_4_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_4,
            LEVEL_5,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_5_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_5_FULL_EXTENDED_DURATION
        );
        assertTotalNftData([1, 1, 1, 1, 1], zeroAmounts);
    }

    function test_With2Users_Mint_UpdateToLevel5_Activate_Transfer() external {
        /**
         * 1. Alice mints Nft level 1
         * 2. Alice updates Nft to level 5
         * 3. Alice activates Nft level 5
         * 4. Alice transfers Nft level 5 to Bob
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_5, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        nft.safeTransferFrom(alice, bob, NFT_TOKEN_ID_1);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(alice, [NFT_TOKEN_ID_0]);
        assertUserOwnedNfts(bob, [NFT_TOKEN_ID_1]);
        assertNftData(NFT_TOKEN_ID_0, LEVEL_1, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_1,
            LEVEL_5,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_5_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_5_FULL_EXTENDED_DURATION
        );
        assertTotalNftData([1, 0, 0, 0, 1], zeroAmounts);
    }

    function test_With2Users_Mint_Activate_UpdateAndActivateLevel5_Transfer()
        external
    {
        /**
         * 1. Alice mints Nft level 1
         * 2. Alice activates Nft level 1
         * 3. Alice updates Nft to level 5
         * 4. Alice activates Nft level 5
         * 5. Alice transfers Nft level 5 to Bob
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_5, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        nft.safeTransferFrom(alice, bob, NFT_TOKEN_ID_1);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(alice, [NFT_TOKEN_ID_0]);
        assertUserOwnedNfts(bob, [NFT_TOKEN_ID_1]);
        assertNftData(
            NFT_TOKEN_ID_0,
            LEVEL_1,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_1_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_1,
            LEVEL_5,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_5_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_5_FULL_EXTENDED_DURATION
        );
        assertTotalNftData([1, 0, 0, 0, 1], zeroAmounts);
    }

    function test_With2Users_MintsGenesis_Activate_Transfer() external {
        /**
         * 1. Alice mints Genesis Nft level 1
         * 2. Alice activates Genesis Nft level 1
         * 3. Alice transfers Genesis Nft level 1 to Bob
         */

        // ARRANGE + ACT
        vm.prank(admin);
        sale.mintGenesisNfts(
            singleReceiverArray,
            singleLevelArray,
            false,
            true
        );

        vm.startPrank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        nft.safeTransferFrom(alice, bob, NFT_TOKEN_ID_0);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(bob, [NFT_TOKEN_ID_0]);
        assertNftData(
            NFT_TOKEN_ID_0,
            LEVEL_1,
            true,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_1_FULL_EXTENDED_DURATION
        );
        assertTotalNftData(zeroAmounts, [1, 0, 0, 0, 0]);
    }

    function test_With2Users_Mint_Update_Activate_Transfer_Update_Activate_Transfer()
        external
    {
        /**
         * 1. Alice mints Nft level 1
         * 2. Alice updates Nft to level 2
         * 3. Alice activates Nft level 2
         * 4. Alice transfers Nft level 2 to Bob
         * 5. Bob updates Nft to level 3
         * 6. Bob activates Nft level 3
         * 7. Bob transfers Nft level 3 to Alice
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        nft.safeTransferFrom(alice, bob, NFT_TOKEN_ID_1);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenUSDC.approve(address(sale), type(uint256).max);
        sale.updateNft(NFT_TOKEN_ID_1, LEVEL_3, tokenUSDC);
        nft.activateNftData(NFT_TOKEN_ID_2, true);
        nft.safeTransferFrom(bob, alice, NFT_TOKEN_ID_2);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(alice, [NFT_TOKEN_ID_0, NFT_TOKEN_ID_2]);
        assertUserOwnedNfts(bob, [NFT_TOKEN_ID_1]);
        assertNftData(NFT_TOKEN_ID_0, LEVEL_1, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_1,
            LEVEL_2,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_2_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_2_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_2,
            LEVEL_3,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_3_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_3_FULL_EXTENDED_DURATION
        );
        assertTotalNftData([1, 1, 1, 0, 0], zeroAmounts);
    }

    function test_With3Users_Mint_Update_Activate_Transfer() external {
        /**
         * 1. Alice mints Nft level 1
         * 2. Alice updates Nft to level 2
         * 3. Alice activates Nft level 2
         * 4. Bob mints Nft level 1
         * 5. Bob updates Nft to level 2
         * 6. Bob activates Nft level 2
         * 7. Carol mints Nft level 1
         * 8. Carol updates Nft to level 2
         * 9. Carol activates Nft level 2
         * 10. Alice transfers Nft level 2 to Dan
         * 11. Bob transfers Nft level 2 to Dan
         * 12. Carol transfers Nft level 2 to Dan
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        nft.safeTransferFrom(alice, dan, NFT_TOKEN_ID_1);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenUSDC.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDC);
        sale.updateNft(NFT_TOKEN_ID_2, LEVEL_2, tokenUSDC);
        nft.activateNftData(NFT_TOKEN_ID_3, true);
        nft.safeTransferFrom(bob, dan, NFT_TOKEN_ID_3);
        vm.stopPrank();

        vm.startPrank(carol);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_4, LEVEL_2, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_5, true);
        nft.safeTransferFrom(carol, dan, NFT_TOKEN_ID_5);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(alice, [NFT_TOKEN_ID_0]);
        assertUserOwnedNfts(bob, [NFT_TOKEN_ID_2]);
        assertUserOwnedNfts(carol, [NFT_TOKEN_ID_4]);
        assertUserOwnedNfts(
            dan,
            [NFT_TOKEN_ID_1, NFT_TOKEN_ID_3, NFT_TOKEN_ID_5]
        );
        assertNftData(NFT_TOKEN_ID_0, LEVEL_1, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_1,
            LEVEL_2,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_2_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_2_FULL_EXTENDED_DURATION
        );
        assertNftData(NFT_TOKEN_ID_2, LEVEL_1, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_3,
            LEVEL_2,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_2_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_2_FULL_EXTENDED_DURATION
        );
        assertNftData(NFT_TOKEN_ID_4, LEVEL_1, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_5,
            LEVEL_2,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_2_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_2_FULL_EXTENDED_DURATION
        );
        assertTotalNftData([3, 3, 0, 0, 0], zeroAmounts);
    }

    function test_With3Users_MintB_Activate_Update_Transfer() external {
        /**
         * 1. Alice mints Nft level 1
         * 2. Alice activates Nft level 1
         * 3. Alice updates Nft to level 2
         * 4. Bob mints Nft level 1
         * 5. Bob activates Nft level 1
         * 6. Bob updates Nft to level 2
         * 7. Carol mints Nft level 1
         * 8. Carol activates Nft level 1
         * 9. Carol updates Nft to level 2
         * 10. Alice transfers Nft level 2 to Dan
         * 11. Bob transfers Nft level 2 to Dan
         * 12. Carol transfers Nft level 2 to Dan
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, tokenUSDT);
        nft.safeTransferFrom(alice, dan, NFT_TOKEN_ID_1);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenUSDC.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDC);
        nft.activateNftData(NFT_TOKEN_ID_2, true);
        sale.updateNft(NFT_TOKEN_ID_2, LEVEL_2, tokenUSDC);
        nft.safeTransferFrom(bob, dan, NFT_TOKEN_ID_3);
        vm.stopPrank();

        vm.startPrank(carol);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_4, true);
        sale.updateNft(NFT_TOKEN_ID_4, LEVEL_2, tokenUSDT);
        nft.safeTransferFrom(carol, dan, NFT_TOKEN_ID_5);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(alice, [NFT_TOKEN_ID_0]);
        assertUserOwnedNfts(bob, [NFT_TOKEN_ID_2]);
        assertUserOwnedNfts(carol, [NFT_TOKEN_ID_4]);
        assertUserOwnedNfts(
            dan,
            [NFT_TOKEN_ID_1, NFT_TOKEN_ID_3, NFT_TOKEN_ID_5]
        );
        assertNftData(
            NFT_TOKEN_ID_0,
            LEVEL_1,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_1_FULL_EXTENDED_DURATION
        );
        assertNftData(NFT_TOKEN_ID_1, LEVEL_2, false, NFT_NOT_ACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_2,
            LEVEL_1,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_1_FULL_EXTENDED_DURATION
        );
        assertNftData(NFT_TOKEN_ID_3, LEVEL_2, false, NFT_NOT_ACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_4,
            LEVEL_1,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_1_FULL_EXTENDED_DURATION
        );
        assertNftData(NFT_TOKEN_ID_5, LEVEL_2, false, NFT_NOT_ACTIVATED, 0, 0);
        assertTotalNftData([3, 3, 0, 0, 0], zeroAmounts);
    }

    function test_With3Users_Mint_Activate_Update_Activate_Transfer() external {
        /**
         * 1. Alice mints Nft level 1
         * 2. Alice activates Nft level 1
         * 3. Alice updates Nft to level 2
         * 4. Alice activates Nft level 2
         * 5. Bob mints Nft level 1
         * 6. Bob activates Nft level 1
         * 7. Bob updates Nft to level 2
         * 8. Bob activates Nft level 2
         * 9. Carol mints Nft level 1
         * 10. Carol activates Nft level 1
         * 11. Carol updates Nft to level 2
         * 12. Carol activates Nft level 2
         * 13. Alice transfers Nft level 2 to Dan
         * 14. Bob transfers Nft level 2 to Dan
         * 15. Carol transfers Nft level 2 to Dan
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        nft.safeTransferFrom(alice, dan, NFT_TOKEN_ID_1);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenUSDC.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDC);
        nft.activateNftData(NFT_TOKEN_ID_2, true);
        sale.updateNft(NFT_TOKEN_ID_2, LEVEL_2, tokenUSDC);
        nft.activateNftData(NFT_TOKEN_ID_3, true);
        nft.safeTransferFrom(bob, dan, NFT_TOKEN_ID_3);
        vm.stopPrank();

        vm.startPrank(carol);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_4, true);
        sale.updateNft(NFT_TOKEN_ID_4, LEVEL_2, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_5, true);
        nft.safeTransferFrom(carol, dan, NFT_TOKEN_ID_5);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(alice, [NFT_TOKEN_ID_0]);
        assertUserOwnedNfts(bob, [NFT_TOKEN_ID_2]);
        assertUserOwnedNfts(carol, [NFT_TOKEN_ID_4]);
        assertUserOwnedNfts(
            dan,
            [NFT_TOKEN_ID_1, NFT_TOKEN_ID_3, NFT_TOKEN_ID_5]
        );
        assertNftData(
            NFT_TOKEN_ID_0,
            LEVEL_1,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_1_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_1,
            LEVEL_2,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_2_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_2_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_2,
            LEVEL_1,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_1_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_3,
            LEVEL_2,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_2_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_2_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_4,
            LEVEL_1,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_1_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_5,
            LEVEL_2,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_2_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_2_FULL_EXTENDED_DURATION
        );
        assertTotalNftData([3, 3, 0, 0, 0], zeroAmounts);
    }

    function test_With3Users_Mint_Update5Times_Activate_Transfer() external {
        /**
         * 1. Alice mints Nft level 1
         * 2. Alice updates Nft to level 2
         * 3. Alice updates Nft to level 3
         * 4. Alice updates Nft to level 4
         * 5. Alice updates Nft to level 5
         * 6. Alice activates Nft level 5
         * 7. Bob mints Nft level 1
         * 8. Bob updates Nft to level 2
         * 9. Bob updates Nft to level 3
         * 10. Bob updates Nft to level 4
         * 11. Bob updates Nft to level 5
         * 12. Bob activates Nft level 5
         * 13. Carol mints Nft level 1
         * 14. Carol updates Nft to level 2
         * 15. Carol updates Nft to level 3
         * 16. Carol updates Nft to level 4
         * 17. Carol updates Nft to level 5
         * 18. Carol activates Nft level 5
         * 19. Alice transfers Nft level 5 to Dan
         * 20. Bob transfers Nft level 5 to Dan
         * 21. Carol transfers Nft level 5 to Dan
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_2, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_1, LEVEL_3, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_2, LEVEL_4, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_3, LEVEL_5, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_4, true);
        nft.safeTransferFrom(alice, dan, NFT_TOKEN_ID_4);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenUSDC.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDC);
        sale.updateNft(NFT_TOKEN_ID_5, LEVEL_2, tokenUSDC);
        sale.updateNft(NFT_TOKEN_ID_6, LEVEL_3, tokenUSDC);
        sale.updateNft(NFT_TOKEN_ID_7, LEVEL_4, tokenUSDC);
        sale.updateNft(NFT_TOKEN_ID_8, LEVEL_5, tokenUSDC);
        nft.activateNftData(NFT_TOKEN_ID_9, true);
        nft.safeTransferFrom(bob, dan, NFT_TOKEN_ID_9);
        vm.stopPrank();

        vm.startPrank(carol);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_1, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_10, LEVEL_2, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_11, LEVEL_3, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_12, LEVEL_4, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_13, LEVEL_5, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_14, true);
        nft.safeTransferFrom(carol, dan, NFT_TOKEN_ID_14);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(
            alice,
            [NFT_TOKEN_ID_0, NFT_TOKEN_ID_1, NFT_TOKEN_ID_2, NFT_TOKEN_ID_3]
        );
        assertUserOwnedNfts(
            bob,
            [NFT_TOKEN_ID_5, NFT_TOKEN_ID_6, NFT_TOKEN_ID_7, NFT_TOKEN_ID_8]
        );
        assertUserOwnedNfts(
            carol,
            [NFT_TOKEN_ID_10, NFT_TOKEN_ID_11, NFT_TOKEN_ID_12, NFT_TOKEN_ID_13]
        );
        assertUserOwnedNfts(
            dan,
            [NFT_TOKEN_ID_4, NFT_TOKEN_ID_9, NFT_TOKEN_ID_14]
        );
        assertNftData(NFT_TOKEN_ID_0, LEVEL_1, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(NFT_TOKEN_ID_1, LEVEL_2, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(NFT_TOKEN_ID_2, LEVEL_3, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(NFT_TOKEN_ID_3, LEVEL_4, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_4,
            LEVEL_5,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_5_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_5_FULL_EXTENDED_DURATION
        );
        assertNftData(NFT_TOKEN_ID_5, LEVEL_1, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(NFT_TOKEN_ID_6, LEVEL_2, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(NFT_TOKEN_ID_7, LEVEL_3, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(NFT_TOKEN_ID_8, LEVEL_4, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_9,
            LEVEL_5,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_5_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_5_FULL_EXTENDED_DURATION
        );

        assertNftData(NFT_TOKEN_ID_10, LEVEL_1, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(NFT_TOKEN_ID_11, LEVEL_2, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(NFT_TOKEN_ID_12, LEVEL_3, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(NFT_TOKEN_ID_13, LEVEL_4, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_14,
            LEVEL_5,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_5_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_5_FULL_EXTENDED_DURATION
        );
        assertTotalNftData([3, 3, 3, 3, 3], zeroAmounts);
    }

    function test_With3Users_Mint_UpdateToLevel5_Activate_Transfer() external {
        /**
         * 1. Alice mints Nft level 3
         * 2. Alice updates Nft to level 5
         * 3. Alice activates Nft level 5
         * 4. Bob mints Nft level 3
         * 5. Bob updates Nft to level 5
         * 6. Bob activates Nft level 5
         * 7. Carol mints Nft level 3
         * 8. Carol updates Nft to level 5
         * 9. Carol activates Nft level 5
         * 10. Alice transfers Nft level 5 to Dan
         * 11. Bob transfers Nft level 5 to Dan
         * 12. Carol transfers Nft level 5 to Dan
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_3, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_5, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        nft.safeTransferFrom(alice, dan, NFT_TOKEN_ID_1);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenUSDC.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_3, tokenUSDC);
        sale.updateNft(NFT_TOKEN_ID_2, LEVEL_5, tokenUSDC);
        nft.activateNftData(NFT_TOKEN_ID_3, true);
        nft.safeTransferFrom(bob, dan, NFT_TOKEN_ID_3);
        vm.stopPrank();

        vm.startPrank(carol);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_3, tokenUSDT);
        sale.updateNft(NFT_TOKEN_ID_4, LEVEL_5, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_5, true);
        nft.safeTransferFrom(carol, dan, NFT_TOKEN_ID_5);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(alice, [NFT_TOKEN_ID_0]);
        assertUserOwnedNfts(bob, [NFT_TOKEN_ID_2]);
        assertUserOwnedNfts(carol, [NFT_TOKEN_ID_4]);
        assertUserOwnedNfts(
            dan,
            [NFT_TOKEN_ID_1, NFT_TOKEN_ID_3, NFT_TOKEN_ID_5]
        );
        assertNftData(NFT_TOKEN_ID_0, LEVEL_3, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_1,
            LEVEL_5,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_5_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_5_FULL_EXTENDED_DURATION
        );
        assertNftData(NFT_TOKEN_ID_2, LEVEL_3, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_3,
            LEVEL_5,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_5_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_5_FULL_EXTENDED_DURATION
        );
        assertNftData(NFT_TOKEN_ID_4, LEVEL_3, false, NFT_DEACTIVATED, 0, 0);
        assertNftData(
            NFT_TOKEN_ID_5,
            LEVEL_5,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_5_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_5_FULL_EXTENDED_DURATION
        );
        assertTotalNftData([0, 0, 3, 0, 3], zeroAmounts);
    }

    function test_With3Users_Mint_Activate_UpdateToLevel5_Activate_Transfer()
        external
    {
        /**
         * 1. Alice mints Nft level 1
         * 2. Alice activates Nft level 1
         * 3. Alice updates Nft to level 5
         * 4. Alice activates Nft level 5
         * 5. Bob mints Nft level 1
         * 6. Bob activates Nft level 1
         * 7. Bob updates Nft to level 5
         * 8. Bob activates Nft level 5
         * 9. Carol mints Nft level 1
         * 10. Carol activates Nft level 1
         * 11. Carol updates Nft to level 5
         * 12. Carol activates Nft level 5
         * 13. Alice transfers Nft level 5 to Dan
         * 14. Bob transfers Nft level 5 to Dan
         * 15. Carol transfers Nft level 5 to Dan
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_3, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_5, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        nft.safeTransferFrom(alice, dan, NFT_TOKEN_ID_1);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenUSDC.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_3, tokenUSDC);
        nft.activateNftData(NFT_TOKEN_ID_2, true);
        sale.updateNft(NFT_TOKEN_ID_2, LEVEL_5, tokenUSDC);
        nft.activateNftData(NFT_TOKEN_ID_3, true);
        nft.safeTransferFrom(bob, dan, NFT_TOKEN_ID_3);
        vm.stopPrank();

        vm.startPrank(carol);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_3, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_4, true);
        sale.updateNft(NFT_TOKEN_ID_4, LEVEL_5, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_5, true);
        nft.safeTransferFrom(carol, dan, NFT_TOKEN_ID_5);
        vm.stopPrank();

        // ASSERT
        assertUserOwnedNfts(alice, [NFT_TOKEN_ID_0]);
        assertUserOwnedNfts(bob, [NFT_TOKEN_ID_2]);
        assertUserOwnedNfts(carol, [NFT_TOKEN_ID_4]);
        assertUserOwnedNfts(
            dan,
            [NFT_TOKEN_ID_1, NFT_TOKEN_ID_3, NFT_TOKEN_ID_5]
        );

        assertNftData(
            NFT_TOKEN_ID_0,
            LEVEL_3,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_3_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_3_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_1,
            LEVEL_5,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_5_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_5_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_2,
            LEVEL_3,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_3_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_3_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_3,
            LEVEL_5,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_5_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_5_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_4,
            LEVEL_3,
            false,
            NFT_DEACTIVATED,
            block.timestamp + LEVEL_3_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_3_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_5,
            LEVEL_5,
            false,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_5_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_5_FULL_EXTENDED_DURATION
        );
        assertTotalNftData([0, 0, 3, 0, 3], zeroAmounts);
    }

    function test_With3Users_MintGenesis_Activate_Transfer() external {
        /**
         * 1. Admin mints Genesis Nft level 1 for Alice, Bob and Carol
         * 2. Alice activates Genesis Nft level 1
         * 4. Bob activates Genesis Nft level 1
         * 6. Carol activates Genesis Nft level 1
         * 7. Alice transfers Genesis Nft level 1 to Dan
         * 8. Bob transfers Genesis Nft level 1 to Dan
         * 9. Carol transfers Genesis Nft level 1 to Dan
         */

        // ARRANGE + ACT
        vm.prank(admin);
        sale.mintGenesisNfts(
            threeReceiversArray,
            threeLevelsArray,
            false,
            true
        );

        vm.startPrank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        nft.safeTransferFrom(alice, dan, NFT_TOKEN_ID_0);
        vm.stopPrank();

        vm.startPrank(bob);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        nft.safeTransferFrom(bob, dan, NFT_TOKEN_ID_1);
        vm.stopPrank();

        vm.startPrank(carol);
        nft.activateNftData(NFT_TOKEN_ID_2, true);
        nft.safeTransferFrom(carol, dan, NFT_TOKEN_ID_2);
        vm.stopPrank();

        // ASSERT

        assertUserOwnedNfts(alice);
        assertUserOwnedNfts(bob);
        assertUserOwnedNfts(carol);
        assertUserOwnedNfts(
            dan,
            [NFT_TOKEN_ID_0, NFT_TOKEN_ID_1, NFT_TOKEN_ID_2]
        );
        assertNftData(
            NFT_TOKEN_ID_0,
            LEVEL_1,
            true,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_1_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_1,
            LEVEL_2,
            true,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_2_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_2_FULL_EXTENDED_DURATION
        );
        assertNftData(
            NFT_TOKEN_ID_2,
            LEVEL_3,
            true,
            NFT_ACTIVATION_TRIGGERED,
            block.timestamp + LEVEL_3_LIFECYCLE_DURATION,
            block.timestamp + LEVEL_3_FULL_EXTENDED_DURATION
        );
        assertTotalNftData(zeroAmounts, [1, 1, 1, 0, 0]);
    }

    function test_mintNft_MintsAllLevel5Nfts() external {
        /**
         * 1. Mint Nft level 5 for Alice (20 times)
         */

        // ARRANGE + ACT
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        for (uint256 i; i < 20; i++) {
            sale.mintNft(LEVEL_5, tokenUSDT);
        }
        vm.stopPrank();

        // ASSERT
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Nft__SupplyCapReached.selector,
                LEVEL_5,
                false,
                LEVEL_5_SUPPLY_CAP
            )
        );
        vm.prank(alice);
        sale.mintNft(LEVEL_5, tokenUSDT);
    }
}
