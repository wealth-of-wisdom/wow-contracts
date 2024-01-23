// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Errors} from "../../contracts/libraries/Errors.sol";
import {Base_Test} from "../Base.t.sol";

contract NftSale_E2E_Test is Base_Test {
    function test_With2Users_Mint_Update_Activate_Transfer() external {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice updates Band to level 2
         * 3. Alice activates Band level 2
         * 4. Alice transfers Band level 2 to Bob
         */
    }

    function test_With2Users_Mint_Activate_Update_Transfer() external {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice activates Band level 1
         * 3. Alice updates Band to level 2
         * 4. Alice transfers Band level 2 to Bob
         */
    }

    function test_With2Users_Mint_Activate_Update_Activate_Transfer() external {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice activates Band level 1
         * 3. Alice updates Band to level 2
         * 4. Alice activates Band level 2
         * 5. Alice transfers Band level 2 to Bob
         */
    }

    function test_With2Users_Mint_Update5Times_Activate_Transfer() external {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice updates Band to level 2
         * 3. Alice updates Band to level 3
         * 4. Alice updates Band to level 4
         * 5. Alice updates Band to level 5
         * 6. Alice activates Band level 5
         * 7. Alice transfers Band level 5 to Bob
         */
    }

    function test_With2Users_Mint_UpdateAndActivate5Time_Transfer() external {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice activates Band level 1
         * 3. Alice updates Band to level 2
         * 4. Alice activates Band level 2
         * 5. Alice updates Band to level 3
         * 6. Alice activates Band level 3
         * 7. Alice updates Band to level 4
         * 8. Alice activates Band level 4
         * 9. Alice updates Band to level 5
         * 10. Alice activates Band level 5
         * 11. Alice transfers Band level 5 to Bob
         */
    }

    function test_With2Users_Mint_UpdateToLevel5_Activate_Transfer() external {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice updates Band to level 5
         * 3. Alice activates Band level 5
         * 4. Alice transfers Band level 5 to Bob
         */
    }

    function test_With2Users_Mint_Activate_UpdateAndActivateLevel5_Transfer()
        external
    {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice activates Band level 1
         * 3. Alice updates Band to level 5
         * 4. Alice activates Band level 5
         * 5. Alice transfers Band level 5 to Bob
         */
    }

    function test_With2Users_MintsGenesisBandLevel1_ActivatesBand_TransfersIt()
        external
    {
        /**
         * 1. Alice mints Genesis Band level 1
         * 2. Alice activates Genesis Band level 1
         * 3. Alice transfers Genesis Band level 1 to Bob
         */
    }

    function test_With2Users_Mint_Update_Activate_Transfer_Update_Activate_Transfer()
        external
    {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice updates Band to level 2
         * 3. Alice activates Band level 2
         * 4. Alice transfers Band level 2 to Bob
         * 5. Bob updates Band to level 3
         * 6. Bob activates Band level 3
         * 7. Bob transfers Band level 3 to Alice
         */
    }

    function test_With3Users_Mint_Update_Activate_Transfer() external {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice updates Band to level 2
         * 3. Alice activates Band level 2
         * 4. Bob mints Band level 1
         * 5. Bob updates Band to level 2
         * 6. Bob activates Band level 2
         * 7. Charlie mints Band level 1
         * 8. Charlie updates Band to level 2
         * 9. Charlie activates Band level 2
         * 10. Alice transfers Band level 2 to Dan
         * 11. Bob transfers Band level 2 to Dan
         * 12. Charlie transfers Band level 2 to Dan
         */
    }

    function test_With3Users_MintB_Activate_Update_Transfer() external {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice activates Band level 1
         * 3. Alice updates Band to level 2
         * 4. Bob mints Band level 1
         * 5. Bob activates Band level 1
         * 6. Bob updates Band to level 2
         * 7. Charlie mints Band level 1
         * 8. Charlie activates Band level 1
         * 9. Charlie updates Band to level 2
         * 10. Alice transfers Band level 2 to Dan
         * 11. Bob transfers Band level 2 to Dan
         * 12. Charlie transfers Band level 2 to Dan
         */
    }

    function test_With3Users_Mint_Activate_Update_Activate_Transfer() external {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice activates Band level 1
         * 3. Alice updates Band to level 2
         * 4. Alice activates Band level 2
         * 5. Bob mints Band level 1
         * 6. Bob activates Band level 1
         * 7. Bob updates Band to level 2
         * 8. Bob activates Band level 2
         * 9. Charlie mints Band level 1
         * 10. Charlie activates Band level 1
         * 11. Charlie updates Band to level 2
         * 12. Charlie activates Band level 2
         * 13. Alice transfers Band level 2 to Dan
         * 14. Bob transfers Band level 2 to Dan
         * 15. Charlie transfers Band level 2 to Dan
         */
    }

    function test_With3Users_Mint_Update5Times_Activate_Transfer() external {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice updates Band to level 2
         * 3. Alice updates Band to level 3
         * 4. Alice updates Band to level 4
         * 5. Alice updates Band to level 5
         * 6. Alice activates Band level 5
         * 7. Bob mints Band level 1
         * 8. Bob updates Band to level 2
         * 9. Bob updates Band to level 3
         * 10. Bob updates Band to level 4
         * 11. Bob updates Band to level 5
         * 12. Bob activates Band level 5
         * 13. Charlie mints Band level 1
         * 14. Charlie updates Band to level 2
         * 15. Charlie updates Band to level 3
         * 16. Charlie updates Band to level 4
         * 17. Charlie updates Band to level 5
         * 18. Charlie activates Band level 5
         * 19. Alice transfers Band level 5 to Dan
         * 20. Bob transfers Band level 5 to Dan
         * 21. Charlie transfers Band level 5 to Dan
         */
    }

    function test_With3Users_Mint_Activate_UpdateAndActivat5Times_Transfer()
        external
    {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice activates Band level 1
         * 3. Alice updates Band to level 2
         * 4. Alice activates Band level 2
         * 5. Alice updates Band to level 3
         * 6. Alice activates Band level 3
         * 7. Alice updates Band to level 4
         * 8. Alice activates Band level 4
         * 9. Alice updates Band to level 5
         * 10. Alice activates Band level 5
         * 11. Bob mints Band level 1
         * 12. Bob activates Band level 1
         * 13. Bob updates Band to level 2
         * 14. Bob activates Band level 2
         * 15. Bob updates Band to level 3
         * 16. Bob activates Band level 3
         * 17. Bob updates Band to level 4
         * 18. Bob activates Band level 4
         * 19. Bob updates Band to level 5
         * 20. Bob activates Band level 5
         * 21. Charlie mints Band level 1
         * 22. Charlie activates Band level 1
         * 23. Charlie updates Band to level 2
         * 24. Charlie activates Band level 2
         * 25. Charlie updates Band to level 3
         * 26. Charlie activates Band level 3
         * 27. Charlie updates Band to level 4
         * 28. Charlie activates Band level 4
         * 29. Charlie updates Band to level 5
         * 30. Charlie activates Band level 5
         * 31. Alice transfers Band level 5 to Dan
         * 32. Bob transfers Band level 5 to Dan
         * 33. Charlie transfers Band level 5 to Dan
         */
    }

    function test_With3Users_Mint_UpdateToLevel5_Activate_Transfer() external {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice updates Band to level 5
         * 3. Alice activates Band level 5
         * 4. Bob mints Band level 1
         * 5. Bob updates Band to level 5
         * 6. Bob activates Band level 5
         * 7. Charlie mints Band level 1
         * 8. Charlie updates Band to level 5
         * 9. Charlie activates Band level 5
         * 10. Alice transfers Band level 5 to Dan
         * 11. Bob transfers Band level 5 to Dan
         * 12. Charlie transfers Band level 5 to Dan
         */
    }

    function test_With3Users_Mint_Activate_UpdateToLevel5_Activate_Transfer()
        external
    {
        /**
         * 1. Alice mints Band level 1
         * 2. Alice activates Band level 1
         * 3. Alice updates Band to level 5
         * 4. Alice activates Band level 5
         * 5. Bob mints Band level 1
         * 6. Bob activates Band level 1
         * 7. Bob updates Band to level 5
         * 8. Bob activates Band level 5
         * 9. Charlie mints Band level 1
         * 10. Charlie activates Band level 1
         * 11. Charlie updates Band to level 5
         * 12. Charlie activates Band level 5
         * 13. Alice transfers Band level 5 to Dan
         * 14. Bob transfers Band level 5 to Dan
         * 15. Charlie transfers Band level 5 to Dan
         */
    }

    function test_With3Users_MintGenesis_Activate_Transfer() external {
        /**
         * 1. Alice mints Genesis Band level 1
         * 2. Alice activates Genesis Band level 1
         * 3. Bob mints Genesis Band level 1
         * 4. Bob activates Genesis Band level 1
         * 5. Charlie mints Genesis Band level 1
         * 6. Charlie activates Genesis Band level 1
         * 7. Alice transfers Genesis Band level 1 to Dan
         * 8. Bob transfers Genesis Band level 1 to Dan
         * 9. Charlie transfers Genesis Band level 1 to Dan
         */
    }
}
