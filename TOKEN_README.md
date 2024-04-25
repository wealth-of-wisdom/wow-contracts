# The WOW Wealth Protocol
Tokens will be available for claiming in the [Wealth Of Wisdom plaftorm](https://wealthofwisdom.io/wow-token/). 
Every purchase of a WOW Token contributes directly to the wealth protocol, a pool of capital allocated to finance promising projects that have the potential to shape the future of technology, sustainability, and decentralized finance. This unique model ensures that WOW Token holders are directly connected to the success of these ventures when they stake their tokens.

# Token standard
The WOWToken is based on the ERC20 token standard and is using the OpenZeppelin implementation. All OpenZeppelin integrations are tested on their end and are approved. Our testing includes all functions added post implementation. Some internal functions such as **_authorizeUpgrade** or **_update** ar necesarry override functions when inheriting OpenZeppelin libraries.

# Deployment
### Main token contract code
[WOWToken.sol](packages/smart-contracts/packages/token/contracts/WOWToken.sol)

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

Edit [config.json](packages/smart-contracts/packages/token/scripts/data/config.json) file to set up contract deployment data:

```bash
"name": "",
"symbol": "",
"initial_token_amount_in_eth": ""
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
yarn deploy:ethereum
```

- For deployment on sepolia:
```bash
yarn deploy:sepolia
```

- For deployment on arbitrum one:
```bash
yarn deploy:arbitrum-one
```

- For deployment on arbitrum sepolia:
```bash
yarn deploy:arbitrum-sepolia
```

