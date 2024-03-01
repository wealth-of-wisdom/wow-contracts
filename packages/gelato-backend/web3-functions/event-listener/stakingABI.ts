export const stakingABI = [
    { inputs: [], name: "AccessControlBadConfirmation", type: "error" },
    {
        inputs: [
            { internalType: "address", name: "account", type: "address" },
            { internalType: "bytes32", name: "neededRole", type: "bytes32" },
        ],
        name: "AccessControlUnauthorizedAccount",
        type: "error",
    },
    {
        inputs: [{ internalType: "address", name: "target", type: "address" }],
        name: "AddressEmptyCode",
        type: "error",
    },
    {
        inputs: [{ internalType: "address", name: "account", type: "address" }],
        name: "AddressInsufficientBalance",
        type: "error",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "implementation",
                type: "address",
            },
        ],
        name: "ERC1967InvalidImplementation",
        type: "error",
    },
    { inputs: [], name: "ERC1967NonPayable", type: "error" },
    { inputs: [], name: "FailedInnerCall", type: "error" },
    { inputs: [], name: "InvalidInitialization", type: "error" },
    { inputs: [], name: "NotInitializing", type: "error" },
    {
        inputs: [{ internalType: "address", name: "token", type: "address" }],
        name: "SafeERC20FailedOperation",
        type: "error",
    },
    {
        inputs: [
            { internalType: "bool", name: "areTokensVested", type: "bool" },
        ],
        name: "Staking__BandFromVestedTokens",
        type: "error",
    },
    {
        inputs: [
            {
                internalType: "uint256",
                name: "contractBalance",
                type: "uint256",
            },
            {
                internalType: "uint256",
                name: "requiredAmount",
                type: "uint256",
            },
        ],
        name: "Staking__InsufficientContractBalance",
        type: "error",
    },
    {
        inputs: [{ internalType: "uint16", name: "bandLevel", type: "uint16" }],
        name: "Staking__InvalidBandLevel",
        type: "error",
    },
    {
        inputs: [
            { internalType: "uint48", name: "percentage", type: "uint48" },
        ],
        name: "Staking__InvalidDistributionPercentage",
        type: "error",
    },
    {
        inputs: [{ internalType: "uint8", name: "month", type: "uint8" }],
        name: "Staking__InvalidMonth",
        type: "error",
    },
    {
        inputs: [{ internalType: "uint16", name: "poolId", type: "uint16" }],
        name: "Staking__InvalidPoolId",
        type: "error",
    },
    { inputs: [], name: "Staking__MaximumLevelExceeded", type: "error" },
    {
        inputs: [
            { internalType: "uint256", name: "stakersLength", type: "uint256" },
            { internalType: "uint256", name: "rewardsLength", type: "uint256" },
        ],
        name: "Staking__MismatchedArrayLengths",
        type: "error",
    },
    { inputs: [], name: "Staking__NoRewardsToClaim", type: "error" },
    { inputs: [], name: "Staking__NonExistantToken", type: "error" },
    {
        inputs: [
            { internalType: "uint256", name: "bandId", type: "uint256" },
            { internalType: "address", name: "owner", type: "address" },
        ],
        name: "Staking__NotBandOwner",
        type: "error",
    },
    { inputs: [], name: "Staking__NotFlexiTypeBand", type: "error" },
    { inputs: [], name: "Staking__UnlockDateNotReached", type: "error" },
    { inputs: [], name: "Staking__ZeroAddress", type: "error" },
    { inputs: [], name: "Staking__ZeroAmount", type: "error" },
    { inputs: [], name: "UUPSUnauthorizedCallContext", type: "error" },
    {
        inputs: [{ internalType: "bytes32", name: "slot", type: "bytes32" }],
        name: "UUPSUnsupportedProxiableUUID",
        type: "error",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "address",
                name: "user",
                type: "address",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "bandId",
                type: "uint256",
            },
            {
                indexed: false,
                internalType: "uint16",
                name: "oldBandLevel",
                type: "uint16",
            },
            {
                indexed: false,
                internalType: "uint16",
                name: "newBandLevel",
                type: "uint16",
            },
        ],
        name: "BandDowngraded",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: true,
                internalType: "uint16",
                name: "bandLevel",
                type: "uint16",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "price",
                type: "uint256",
            },
            {
                indexed: false,
                internalType: "uint16[]",
                name: "accessiblePools",
                type: "uint16[]",
            },
        ],
        name: "BandLevelSet",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "address",
                name: "user",
                type: "address",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "bandId",
                type: "uint256",
            },
            {
                indexed: false,
                internalType: "uint16",
                name: "oldBandLevel",
                type: "uint16",
            },
            {
                indexed: false,
                internalType: "uint16",
                name: "newBandLevel",
                type: "uint16",
            },
        ],
        name: "BandUpgaded",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "contract IERC20",
                name: "token",
                type: "address",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "amount",
                type: "uint256",
            },
            {
                indexed: false,
                internalType: "uint16",
                name: "totalPools",
                type: "uint16",
            },
            {
                indexed: false,
                internalType: "uint16",
                name: "totalBandLevels",
                type: "uint16",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "totalStakers",
                type: "uint256",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "distributionTimestamp",
                type: "uint256",
            },
        ],
        name: "DistributionCreated",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "uint64",
                name: "version",
                type: "uint64",
            },
        ],
        name: "Initialized",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: true,
                internalType: "uint16",
                name: "poolId",
                type: "uint16",
            },
            {
                indexed: false,
                internalType: "uint48",
                name: "distributionPercentage",
                type: "uint48",
            },
        ],
        name: "PoolSet",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "address",
                name: "user",
                type: "address",
            },
            {
                indexed: false,
                internalType: "contract IERC20",
                name: "token",
                type: "address",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "totalRewards",
                type: "uint256",
            },
        ],
        name: "RewardsClaimed",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "address",
                name: "collector",
                type: "address",
            },
        ],
        name: "RewardsCollectorSet",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "contract IERC20",
                name: "token",
                type: "address",
            },
        ],
        name: "RewardsDistributed",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: true,
                internalType: "bytes32",
                name: "role",
                type: "bytes32",
            },
            {
                indexed: true,
                internalType: "bytes32",
                name: "previousAdminRole",
                type: "bytes32",
            },
            {
                indexed: true,
                internalType: "bytes32",
                name: "newAdminRole",
                type: "bytes32",
            },
        ],
        name: "RoleAdminChanged",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: true,
                internalType: "bytes32",
                name: "role",
                type: "bytes32",
            },
            {
                indexed: true,
                internalType: "address",
                name: "account",
                type: "address",
            },
            {
                indexed: true,
                internalType: "address",
                name: "sender",
                type: "address",
            },
        ],
        name: "RoleGranted",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: true,
                internalType: "bytes32",
                name: "role",
                type: "bytes32",
            },
            {
                indexed: true,
                internalType: "address",
                name: "account",
                type: "address",
            },
            {
                indexed: true,
                internalType: "address",
                name: "sender",
                type: "address",
            },
        ],
        name: "RoleRevoked",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "uint48[]",
                name: "totalSharesInMonth",
                type: "uint48[]",
            },
        ],
        name: "SharesInMonthSet",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "address",
                name: "user",
                type: "address",
            },
            {
                indexed: false,
                internalType: "uint16",
                name: "bandLevel",
                type: "uint16",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "bandId",
                type: "uint256",
            },
            {
                indexed: false,
                internalType: "enum IStaking.StakingTypes",
                name: "stakingType",
                type: "uint8",
            },
            {
                indexed: false,
                internalType: "bool",
                name: "areTokensVested",
                type: "bool",
            },
        ],
        name: "Staked",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "contract IERC20",
                name: "token",
                type: "address",
            },
            {
                indexed: false,
                internalType: "address",
                name: "receiver",
                type: "address",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "amount",
                type: "uint256",
            },
        ],
        name: "TokensWithdrawn",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "uint16",
                name: "newTotalBandsAmount",
                type: "uint16",
            },
        ],
        name: "TotalBandLevelsAmountSet",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "uint16",
                name: "newTotalPoolAmount",
                type: "uint16",
            },
        ],
        name: "TotalPoolAmountSet",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "address",
                name: "user",
                type: "address",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "bandId",
                type: "uint256",
            },
            {
                indexed: false,
                internalType: "bool",
                name: "areTokensVested",
                type: "bool",
            },
        ],
        name: "Unstaked",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: true,
                internalType: "address",
                name: "implementation",
                type: "address",
            },
        ],
        name: "Upgraded",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "contract IERC20",
                name: "token",
                type: "address",
            },
        ],
        name: "UsdcTokenSet",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "contract IERC20",
                name: "token",
                type: "address",
            },
        ],
        name: "UsdtTokenSet",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "address",
                name: "user",
                type: "address",
            },
        ],
        name: "VestingUserDeleted",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: false,
                internalType: "contract IERC20",
                name: "token",
                type: "address",
            },
        ],
        name: "WowTokenSet",
        type: "event",
    },
    {
        inputs: [],
        name: "DEFAULT_ADMIN_ROLE",
        outputs: [{ internalType: "bytes32", name: "", type: "bytes32" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "GELATO_EXECUTOR_ROLE",
        outputs: [{ internalType: "bytes32", name: "", type: "bytes32" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "PERCENTAGE_PRECISION",
        outputs: [{ internalType: "uint48", name: "", type: "uint48" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "SHARE",
        outputs: [{ internalType: "uint48", name: "", type: "uint48" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "UPGRADER_ROLE",
        outputs: [{ internalType: "bytes32", name: "", type: "bytes32" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "UPGRADE_INTERFACE_VERSION",
        outputs: [{ internalType: "string", name: "", type: "string" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "VESTING_ROLE",
        outputs: [{ internalType: "bytes32", name: "", type: "bytes32" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            { internalType: "contract IERC20", name: "token", type: "address" },
        ],
        name: "claimRewards",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "contract IERC20", name: "token", type: "address" },
            { internalType: "uint256", name: "amount", type: "uint256" },
        ],
        name: "createDistribution",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [{ internalType: "address", name: "user", type: "address" }],
        name: "deleteVestingUser",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "contract IERC20", name: "token", type: "address" },
            { internalType: "address[]", name: "stakers", type: "address[]" },
            { internalType: "uint256[]", name: "rewards", type: "uint256[]" },
        ],
        name: "distributeRewards",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "uint256", name: "bandId", type: "uint256" },
            { internalType: "uint16", name: "newBandLevel", type: "uint16" },
        ],
        name: "downgradeBand",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [{ internalType: "uint16", name: "bandLevel", type: "uint16" }],
        name: "getBandLevel",
        outputs: [
            { internalType: "uint256", name: "price", type: "uint256" },
            {
                internalType: "uint16[]",
                name: "accessiblePools",
                type: "uint16[]",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "getNextBandId",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [{ internalType: "uint16", name: "poolId", type: "uint16" }],
        name: "getPool",
        outputs: [
            {
                internalType: "uint48",
                name: "distributionPercentage",
                type: "uint48",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [{ internalType: "bytes32", name: "role", type: "bytes32" }],
        name: "getRoleAdmin",
        outputs: [{ internalType: "bytes32", name: "", type: "bytes32" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [{ internalType: "uint256", name: "index", type: "uint256" }],
        name: "getSharesInMonth",
        outputs: [{ internalType: "uint48", name: "shares", type: "uint48" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "getSharesInMonthArray",
        outputs: [{ internalType: "uint48[]", name: "", type: "uint48[]" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [{ internalType: "uint256", name: "bandId", type: "uint256" }],
        name: "getStakerBand",
        outputs: [
            { internalType: "address", name: "owner", type: "address" },
            {
                internalType: "uint32",
                name: "stakingStartDate",
                type: "uint32",
            },
            { internalType: "uint16", name: "bandLevel", type: "uint16" },
            { internalType: "uint8", name: "fixedMonths", type: "uint8" },
            {
                internalType: "enum IStaking.StakingTypes",
                name: "stakingType",
                type: "uint8",
            },
            { internalType: "bool", name: "areTokensVested", type: "bool" },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [{ internalType: "address", name: "staker", type: "address" }],
        name: "getStakerBandIds",
        outputs: [
            { internalType: "uint256[]", name: "bandIds", type: "uint256[]" },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            { internalType: "address", name: "staker", type: "address" },
            { internalType: "contract IERC20", name: "token", type: "address" },
        ],
        name: "getStakerReward",
        outputs: [
            {
                internalType: "uint256",
                name: "unclaimedAmount",
                type: "uint256",
            },
            { internalType: "uint256", name: "claimedAmount", type: "uint256" },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "getTokenUSDC",
        outputs: [
            { internalType: "contract IERC20", name: "", type: "address" },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "getTokenUSDT",
        outputs: [
            { internalType: "contract IERC20", name: "", type: "address" },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "getTokenWOW",
        outputs: [
            { internalType: "contract IERC20", name: "", type: "address" },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "getTotalBandLevels",
        outputs: [{ internalType: "uint16", name: "", type: "uint16" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "getTotalPools",
        outputs: [{ internalType: "uint16", name: "", type: "uint16" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "getTotalUsers",
        outputs: [
            { internalType: "uint256", name: "usersAmount", type: "uint256" },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [{ internalType: "uint256", name: "index", type: "uint256" }],
        name: "getUser",
        outputs: [{ internalType: "address", name: "user", type: "address" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            { internalType: "bytes32", name: "role", type: "bytes32" },
            { internalType: "address", name: "account", type: "address" },
        ],
        name: "grantRole",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "bytes32", name: "role", type: "bytes32" },
            { internalType: "address", name: "account", type: "address" },
        ],
        name: "hasRole",
        outputs: [{ internalType: "bool", name: "", type: "bool" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "contract IERC20",
                name: "usdtToken",
                type: "address",
            },
            {
                internalType: "contract IERC20",
                name: "usdcToken",
                type: "address",
            },
            {
                internalType: "contract IERC20",
                name: "wowToken",
                type: "address",
            },
            { internalType: "address", name: "vesting", type: "address" },
            { internalType: "address", name: "gelato", type: "address" },
            { internalType: "uint16", name: "totalPools", type: "uint16" },
            { internalType: "uint16", name: "totalBandLevels", type: "uint16" },
        ],
        name: "initialize",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [],
        name: "proxiableUUID",
        outputs: [{ internalType: "bytes32", name: "", type: "bytes32" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            { internalType: "bytes32", name: "role", type: "bytes32" },
            {
                internalType: "address",
                name: "callerConfirmation",
                type: "address",
            },
        ],
        name: "renounceRole",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "bytes32", name: "role", type: "bytes32" },
            { internalType: "address", name: "account", type: "address" },
        ],
        name: "revokeRole",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "uint16", name: "bandLevel", type: "uint16" },
            { internalType: "uint256", name: "price", type: "uint256" },
            {
                internalType: "uint16[]",
                name: "accessiblePools",
                type: "uint16[]",
            },
        ],
        name: "setBandLevel",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "uint16", name: "poolId", type: "uint16" },
            {
                internalType: "uint48",
                name: "distributionPercentage",
                type: "uint48",
            },
        ],
        name: "setPool",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "uint48[]",
                name: "totalSharesInMonth",
                type: "uint48[]",
            },
        ],
        name: "setSharesInMonth",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "uint16",
                name: "newTotalBandsAmount",
                type: "uint16",
            },
        ],
        name: "setTotalBandLevelsAmount",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "uint16",
                name: "newTotalPoolAmount",
                type: "uint16",
            },
        ],
        name: "setTotalPoolAmount",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "contract IERC20", name: "token", type: "address" },
        ],
        name: "setUsdcToken",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "contract IERC20", name: "token", type: "address" },
        ],
        name: "setUsdtToken",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "contract IERC20", name: "token", type: "address" },
        ],
        name: "setWowToken",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "enum IStaking.StakingTypes",
                name: "stakingType",
                type: "uint8",
            },
            { internalType: "uint16", name: "bandLevel", type: "uint16" },
            { internalType: "uint8", name: "month", type: "uint8" },
        ],
        name: "stake",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "address", name: "user", type: "address" },
            {
                internalType: "enum IStaking.StakingTypes",
                name: "stakingType",
                type: "uint8",
            },
            { internalType: "uint16", name: "bandLevel", type: "uint16" },
            { internalType: "uint8", name: "month", type: "uint8" },
        ],
        name: "stakeVested",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "bytes4", name: "interfaceId", type: "bytes4" },
        ],
        name: "supportsInterface",
        outputs: [{ internalType: "bool", name: "", type: "bool" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [{ internalType: "uint256", name: "bandId", type: "uint256" }],
        name: "unstake",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "address", name: "user", type: "address" },
            { internalType: "uint256", name: "bandId", type: "uint256" },
        ],
        name: "unstakeVested",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "uint256", name: "bandId", type: "uint256" },
            { internalType: "uint16", name: "newBandLevel", type: "uint16" },
        ],
        name: "upgradeBand",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "newImplementation",
                type: "address",
            },
            { internalType: "bytes", name: "data", type: "bytes" },
        ],
        name: "upgradeToAndCall",
        outputs: [],
        stateMutability: "payable",
        type: "function",
    },
    {
        inputs: [
            { internalType: "contract IERC20", name: "token", type: "address" },
            { internalType: "uint256", name: "amount", type: "uint256" },
        ],
        name: "withdrawTokens",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
]