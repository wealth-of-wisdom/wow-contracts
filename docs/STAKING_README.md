# Staking System Overview
[STAKING_FLOW.md](STAKING_FLOW.md)

# Deployment
### Main Staking contract code
[Staking.sol](../packages/smart-contracts/packages/staking/contracts/Staking.sol)

## Prerequisites:
- node  (version >= 18.12.0)
- Ubuntu

```bash
cd packages/smart-contracts
```

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

```bash
cd packages/smart-contracts
```

Set env variables for Staking initializer:
```bash
GELATO_ADDRESS =
```

**NOTE**: ```GELATO_ADDRESS``` (This address will execute rewards distribution and trigger shares sync process)
Visit [Gelato App](https://app.gelato.network/settings) → Choose network → Copy dedicated msg.sender address

Edit [networkConfig.json](../packages/smart-contracts/packages/staking/scripts/data/networkConfig.json) file to set up contract deployment data:

```bash
  "ethereum": {
      "usdt_token": "",
      "usdc_token": "",
      "wow_token": "",
      "vesting_contract": "",
      "total_pools": 9,
      "total_band_levels": 9
  },
  "sepolia": {
      "usdt_token": "",
      "usdc_token": "",
      "wow_token": "",
      "vesting_contract": "",
      "total_pools": 9,
      "total_band_levels": 9
  },
  "arbitrumOne": {
      "usdt_token": "",
      "usdc_token": "",
      "wow_token": "",
      "vesting_contract": "",
      "total_pools": 9,
      "total_band_levels": 9
  },
  "arbitrumSepolia": {
      "usdt_token": "",
      "usdc_token": "",
      "wow_token": "",
      "vesting_contract": "",
      "total_pools": 9,
      "total_band_levels": 9
  }
```

**NOTE**: If these variables are not script will use ```0x0000000000000000000000000000000000000000``` as default address, which will disable some features of Staking Contract

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
