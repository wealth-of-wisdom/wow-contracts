# Main vesting contract code
[Vesting.sol](packages/smart-contracts/packages/vesting/contracts/Vesting.sol)

# Vesting for WOW platform
![Vesting Schedule](Vesting-diagram.png?raw=true) <br />
This contract implements token vesting and claiming for the specified list of beneficiaries.
Vested tokens unlocked: **daily / monthly** after the cliff period ended.

The aim of this project is to distribute ERC20 WOW Tokens to the list of beneficiaries.
Contract can hold multiple pools, however - **the listing date for all pools is the same.**

## Vesting pool data
Vesting pools can be added in the constructor or separately in addVestingPoolFunction.<br />
Example data for pools:

| Vesting Pool          | Tokens      | Listing %  | Cliff release % | Cliff period (months) | Vesting                                              |
|-----------------------|-------------|-------------|-----------------|-----------------------|------------------------------------------------------|
| NFT Holders           | 8,000,000  | 10 %         | 15 %           | 24                     | Mothly                        |
| Community Sale 0.005               | 100,000  | 5 %         | 0 %           | 24                     | Monthly                        |
| Whitelist Sale 0.001             | 21,000,000  | 55 %         | 10 %           | 18                     | Daily   |

# Deployment
## Prerequisites:
- node  (version >= 18.12.0)
- Ubuntu

Edit env file to set up network connection data:
```bash
ETHEREUM_API_KEY=
ETHEREUM_HOST=

SEPOLIA_API_KEY=
SEPOLIA_HOST=

ARBITRUM_ONE_API_KEY=
ARBITRUM_ONE_HOST=

ARBITRUM_SEPOLIA_API_KEY=
ARBITRUM_SEPOLIA_HOST=

PRIVATE_KEY=
```

Edit [networkConfig.json](packages/smart-contracts/packages/vesting/scripts/data/networkConfig.json) file to set up contract deployment data:

```bash
"ethereum": {
        "vesting_token": "",
        "staking_contract": "",
        "listing_date": "",
        "all_pools_token_amount_in_eth": ""
    },
    "sepolia": {
        "vesting_token": "",
        "staking_contract": "",
        "listing_date": "",
        "all_pools_token_amount_in_eth": ""
    },
    "arbitrumOne": {
        "vesting_token": "",
        "staking_contract": "",
        "listing_date": "",
        "all_pools_token_amount_in_eth": ""
    },
    "arbitrumSepolia": {
        "vesting_token": "",
        "staking_contract": "",
        "listing_date": "",
        "all_pools_token_amount_in_eth": ""
    }
```


### 1: Install smart contract dependencies
Enter the smart-contract directory (packages/smart-contractas) and run:
```bash
yarn
```
To test out if everything is installed correctly run:
```bash
yarn build
```
### 2. Test
To tun Vesting contract specific tests and coverage go to packages/smart-contracts/packages/vesting and run:
```bash
yarn test
```

```bash
yarn coverage
```

To generate lcov file and have an html page generated:
```bash
yarn coverage:lcov
```

### 3. Deploy implementation on different networks
- For deployment on ethereum:
```bash
yarn deploy-and-setup:ethereum
```

- For deployment on sepolia:
```bash
yarn deploy-and-setup:sepolia
```

- For deployment on arbitrum one:
```bash
yarn deploy-and-setup:arbitrum-one
```

- For deployment on arbitrum sepolia:
```bash
yarn deploy-and-setup:arbitrum-sepolia
```



# High level documentation
## Roles
- **Default admin role** can add vesting pools with specified listing, cliff percentage and vesting duration.
-	**Default admin role** can change listing date and staking contract.
-	**Default admin role** can remove beneficiary.
-	**Beneficiary manager role** can add multiple or singular beneficiary wallets that are eligible for claiming tokens.
-	**Beneficiary** can claim vested tokens if there are any.
-	**All users** can check vesting pool data.

## Pool Parameters
| Parameter                 | Type               | Explanation                                                                                                                                                                                                         |
|---------------------------|--------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name                      | string             | Pool name                                                                                                                                                                                                           |
| listingPercentageDividend | uint256            | Tokens unlocked on listing date. If listing percentage is 5%,  then dividend is: 1 and divisor is: 20 (1/20 = 0,05)                                                                                                 |
| listingPercentageDivisor  | uint256            |                                                                                                                                                                                                                     |
| cliffInDays                     | uint256            | Cliff period in days.                                                                                                                                                                                               |
| cliffPercentageDividend   | uint256            | Tokens unlocked after cliff period has ended. If cliff percentage is 7,5%,  then dividend is: 3 and divisor is: 40 (3/40 = 0,075)                                                                                   |
| cliffPercentageDivisor    | uint256            |                                                                                                                                                                                                                     |
| vestingDurationInMonths   | uint256            | Duration of vesting period when tokens are linearly unlocked. (Refer to the graph in Vesting contract )                                                                                                             |
| unlockType                | UnlockTypes (enum) | 0 for DAILY; 1 for MONTHLY;                                                                                                                                                                                         |
| poolTokenAmount           | uint256            | Total amount of tokens available for claiming from pool. absolute token amount! If pool has 5 000 000 tokens, contract will accept “5000000000000000000000000” ← value as a paremeter which is ( 5 000 000 * 10 ** 18 ) |

## Beneficiary Parameters

| Parameter   | Type      | Explanation                                                                    |
|-------------|-----------|--------------------------------------------------------------------------------|
| pid   | uint256   | Pool index                                                                     |
| addresses   | address | Beneficiary wallet address                                                  |
| tokenAmount | uint256 | Amount of tokens that can be claimed by beneficiary |

Token amount for beneficiary is recalculated this way: **Total amount = Listing amount + Cliff amount + Vesting amount**

### Claiming tokens
Beneficiaries can claim tokens from the selected pools
- **If listing has started** : listing token amount;
- **If cliff has ended** : listing token amount + cliff token amount + vested unlocked tokens:
 
 <img src="https://latex.codecogs.com/svg.image?unlockedTokens&space;=&space;listingAmount&space;&plus;&space;cliffAmount&space;&plus;&space;\frac{vestingAmount&space;*&space;periodsPassed}{duration}" /><br />

- **If vesting period ended** : transfer all allocated and unclaimed tokens.
