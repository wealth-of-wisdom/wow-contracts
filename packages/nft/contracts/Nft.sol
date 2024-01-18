// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {ERC721BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {INft} from "./interfaces/INft.sol";
import {Errors} from "./libraries/Errors.sol";

contract Nft is
    INft,
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant WHITELISTED_SENDER_ROLE =
        keccak256("WHITELISTED_SENDER_ROLE"); // for transfer authorization
    bytes32 public constant NFT_DATA_MANAGER_ROLE =
        keccak256("NFT_DATA_MANAGER_ROLE");
    string public constant NFT_URI_SUFFIX = ".json";

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */
    mapping(uint256 tokenId => NftData) internal s_nftData; // token ID => nft data
    mapping(uint16 level => NftLevel) internal s_nftLevels; // level => level data
    // level => project (Standard, Premium, Limited) => project amount
    mapping(uint16 level => mapping(uint16 project => uint16 projectAmount))
        internal s_projectsPerNft;

    IVesting internal s_vestingContract;

    uint16 internal s_maxLevel;
    uint16 internal s_promotionalVestingPID;
    uint256 internal s_genesisTokenDivisor;
    uint256 internal s_nextTokenId;

    /* solhint-enable */

    /*//////////////////////////////////////////////////////////////////////////
                                  MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier mAddressNotZero(address addr) {
        if (addr == address(0)) {
            revert Errors.Nft__ZeroAddress();
        }
        _;
    }

    modifier mAmountNotZero(uint256 amount) {
        if (amount == 0) {
            revert Errors.Nft__ZeroAmount();
        }
        _;
    }

    modifier mValidLevel(uint16 level) {
        if (level == 0 || level > s_maxLevel) {
            revert Errors.Nft__InvalidLevel(level);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Initializes the contract with the required parameters
     * @param   name  name of the Nft
     * @param   symbol  symbol of the Nft
     * @param   vestingContract  address of the vesting contract for promotional rewards
     * @param   maxLevel  maximum level of the Nft (levels start from 1)
     * @param   promotionalVestingPID  vesting pool ID for promotional rewards
     * @param   genesisTokenDivisor  divisor for genesis token rewards
     */
    function initialize(
        string memory name,
        string memory symbol,
        IVesting vestingContract,
        uint16 maxLevel,
        uint16 promotionalVestingPID,
        uint256 genesisTokenDivisor
    )
        external
        initializer
        mAddressNotZero(address(vestingContract))
        mAmountNotZero(maxLevel)
        mAmountNotZero(genesisTokenDivisor)
    {
        // Checks: name and symbol must not be empty
        if (bytes(name).length == 0 || bytes(symbol).length == 0) {
            revert Errors.Nft__EmptyString();
        }

        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        // Effects: Set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(WHITELISTED_SENDER_ROLE, msg.sender);
        _grantRole(NFT_DATA_MANAGER_ROLE, msg.sender);

        // Effects: Set up storage
        s_vestingContract = vestingContract;
        s_maxLevel = maxLevel;
        s_promotionalVestingPID = promotionalVestingPID;
        s_genesisTokenDivisor = genesisTokenDivisor;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS MINTER ROLE  
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Mints Nft to user with defined level and type
     * @notice  Sets the token URI using the base URI and the token ID
     * @dev     Only MINTER_ROLE can call this function
     * @param   to  user who will get the Nft
     * @param   level  nft level purchased
     * @param   isGenesis  is it a genesis nft
     */
    function safeMint(
        address to,
        uint16 level,
        bool isGenesis
    ) public onlyRole(MINTER_ROLE) mAddressNotZero(to) mValidLevel(level) {
        // Effects: increment the token id
        // tokenId is assigned prior to incrementing the token id, so it starts from 0
        uint256 tokenId = s_nextTokenId++;

        // Effects: mint the token
        _safeMint(to, tokenId);

        NftLevel storage nftLevel = s_nftLevels[level];

        // Effects: increment the token quantity in the level
        // idInLevel is assigned prior to incrementing the token quantity, so it starts from 0
        uint256 idInLevel = isGenesis
            ? nftLevel.genesisNftAmount++
            : nftLevel.mainNftAmount++;

        string memory baseURI = isGenesis
            ? nftLevel.genesisBaseURI
            : nftLevel.mainBaseURI;

        // Concatenate base URI, id in level and suffix to get the full URI
        string memory uri = string(
            abi.encodePacked(
                baseURI,
                Strings.toString(idInLevel),
                NFT_URI_SUFFIX
            )
        );

        // Effects: set the token metadata URI (URI for each token is assigned before minting)
        _setTokenURI(tokenId, uri);

        emit NftMinted(to, tokenId, uri);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR ALL USERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Sets Nft data state as ACTIVATION_TRIGGERED,
     * @notice  manages other data about the Nft and adds its holder to vesting pool
     * @param   tokenId  user minted and owned token id
     */
    function activateNftData(uint256 tokenId) external {
        // Checks: sender must be the owner of the Nft
        if (ownerOf(tokenId) != msg.sender) {
            revert Errors.Nft__NotNftOwner();
        }

        NftData storage nftData = s_nftData[tokenId];
        NftLevel memory levelData = s_nftLevels[nftData.level];

        // Checks: data must not be activated
        if (nftData.activityType != ActivityType.NOT_ACTIVATED) {
            revert Errors.Nft__AlreadyActivated();
        }

        // Effects: update nft data
        nftData.activityType = ActivityType.ACTIVATION_TRIGGERED;
        nftData.activityEndTimestamp =
            block.timestamp +
            levelData.lifecycleTimestamp;
        nftData.extendedActivityEndTimestamp =
            nftData.activityEndTimestamp +
            levelData.lifecycleExtensionTimestamp;

        (
            ,
            ,
            uint256 totalPoolTokenAmount,
            uint256 dedicatedPoolTokenAmount
        ) = s_vestingContract.getGeneralPoolData(s_promotionalVestingPID);

        // Calculate the amount of tokens that can still be distributed
        uint256 nonDedicatedTokens = totalPoolTokenAmount -
            dedicatedPoolTokenAmount;

        if (nonDedicatedTokens > 0) {
            // If NFT is not genesis, then the reward is fixed
            // If NFT is genesis, then the reward is calculated based on the price
            // Example calculations (40k tokens per 1k spent):
            // 200k rewards = 40k WoW tokens * ( 5k price / 1k )
            uint256 rewardTokens = nftData.isGenesis
                ? levelData.vestingRewardWOWTokens *
                    (levelData.price / s_genesisTokenDivisor)
                : levelData.vestingRewardWOWTokens;

            // If there are enough tokens, then the reward is the minimum of the two
            // Otherwise, the reward is the amount of tokens that can still be distributed
            rewardTokens = (nonDedicatedTokens < rewardTokens)
                ? nonDedicatedTokens
                : rewardTokens;

            // Effects: add the holder to the vesting pool
            s_vestingContract.addBeneficiary(
                s_promotionalVestingPID,
                msg.sender,
                rewardTokens
            );
        }

        emit NftDataActivated(
            msg.sender,
            tokenId,
            nftData.level,
            nftData.isGenesis,
            nftData.activityEndTimestamp,
            nftData.extendedActivityEndTimestamp
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        FUNCTIONS FOR NFT DATA MANAGER ROLE
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  sets all necesary information about the
     * users Nft and its current state
     * @param   tokenId  user minted and owned token id
     * @param   level  nft level purchased
     * @param   isGenesis  is it a genesis nft
     * @param   activityType  activity state of the Nft
     * @param   activityEndTimestamp  Nft regular expiration date
     * @param   extendedActivityEndTimestamp  Nft extended expiration date
     */
    function setNftData(
        uint256 tokenId,
        uint16 level,
        bool isGenesis,
        ActivityType activityType,
        uint256 activityEndTimestamp,
        uint256 extendedActivityEndTimestamp
    ) public onlyRole(NFT_DATA_MANAGER_ROLE) mValidLevel(level) {
        // Effects: set nft data
        s_nftData[tokenId] = NftData({
            level: level,
            isGenesis: isGenesis,
            activityType: activityType,
            activityEndTimestamp: activityEndTimestamp,
            extendedActivityEndTimestamp: extendedActivityEndTimestamp
        });

        emit NftDataSet(
            tokenId,
            level,
            isGenesis,
            uint256(activityType),
            activityEndTimestamp,
            extendedActivityEndTimestamp
        );
    }

    /**
     * @notice  mints Nft to user and sets required data
     * @param   receiver  user who will get the Nft
     * @param   level  nft level purchased
     * @param   isGenesis  is it a genesis nft
     */
    function mintAndSetNftData(
        address receiver,
        uint16 level,
        bool isGenesis
    ) external onlyRole(NFT_DATA_MANAGER_ROLE) {
        // Effects: set nft data with next token id
        setNftData(
            s_nextTokenId,
            level,
            isGenesis,
            INft.ActivityType.NOT_ACTIVATED,
            0,
            0
        );

        // Effects: mint the token and set metadata URI
        safeMint(receiver, level, isGenesis);
    }

    /**
     * @notice  updates data for old Nft token and new one.
     * @notice  Sets necesary states for upgrade - from one level to another
     * @param   receiver  user who will get the Nft
     * @param   oldTokenId  previously owned Nft id, which is being upgraded
     * @param   newLevel  level upgraded to
     */
    function mintAndUpdateNftData(
        address receiver,
        uint256 oldTokenId,
        uint16 newLevel
    ) external onlyRole(NFT_DATA_MANAGER_ROLE) {
        // Effects: deactivate the old NFT
        s_nftData[oldTokenId].activityType = ActivityType.DEACTIVATED;

        // Effects: set nft data with next token id
        setNftData(
            s_nextTokenId,
            newLevel,
            false,
            INft.ActivityType.NOT_ACTIVATED,
            0,
            0
        );

        // Effects: mint the token and set metadata URI
        safeMint(receiver, newLevel, false);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        FUNCTIONS FOR DEFAULT ADMIN ROLE
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Sets the new max level for NFTs
     * @param   maxLevel   new max level
     */
    function setMaxLevel(
        uint16 maxLevel
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: the new max level must be greater than the current max level
        if (maxLevel <= s_maxLevel) {
            revert Errors.Nft__InvalidMaxLevel(maxLevel);
        }

        // Effects: set the new max level
        s_maxLevel = maxLevel;

        emit MaxLevelSet(maxLevel);
    }

    /**
     * @notice  Sets the new genesis token divisor
     * @param   divisor   new divisor
     */
    function setGenesisTokenDivisor(
        uint256 divisor
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAmountNotZero(divisor) {
        // Effects: set the new divisor
        s_genesisTokenDivisor = divisor;

        emit DivisorSet(divisor);
    }

    /**
     * @notice  Sets the new promotional vesting pool ID
     * @param   pid   new vesting pool ID
     */
    function setPromotionalVestingPID(
        uint16 pid
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Effects: set the new vesting pool ID
        s_promotionalVestingPID = pid;

        emit PromotionalVestingPIDSet(pid);
    }

    /**
     * @notice  Sets all data for a level
     * @dev     We don't use modifiers to solve stack too deep error
     * @param   level  level, for which data is being set
     * @param   price  price of the Nft in USDT/USDC
     * @param   vestingRewards  amount of WOW tokens that will be locked into the vesting pool
     * @param   lifecycleTimestamp  duration of the lifecycle
     * @param   lifecycleExtensionTimestamp  duration of the lifecycle extension
     * @param   allocationPerProject  @question what is this for?
     * @param   mainBaseURI  base URI for the main NFT
     * @param   genesisBaseURI  base URI for the Genesis NFT
     */
    function setLevelData(
        uint16 level,
        uint256 price,
        uint256 vestingRewards,
        uint256 lifecycleTimestamp,
        uint256 lifecycleExtensionTimestamp,
        uint256 allocationPerProject,
        string calldata mainBaseURI,
        string calldata genesisBaseURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: level must be valid
        if (level == 0 || level > s_maxLevel) {
            revert Errors.Nft__InvalidLevel(level);
        }

        // Checks: amounts must be greater than 0
        if (price == 0 || lifecycleTimestamp == 0) {
            revert Errors.Nft__ZeroAmount();
        }

        // Checks: base URIs must not be empty
        if (
            bytes(mainBaseURI).length == 0 || bytes(genesisBaseURI).length == 0
        ) {
            revert Errors.Nft__EmptyString();
        }

        // Effects: set level data
        NftLevel storage nftLevel = s_nftLevels[level];
        nftLevel.price = price;
        nftLevel.vestingRewardWOWTokens = vestingRewards;
        nftLevel.lifecycleTimestamp = lifecycleTimestamp;
        nftLevel.lifecycleExtensionTimestamp = lifecycleExtensionTimestamp;
        nftLevel.allocationPerProject = allocationPerProject;
        nftLevel.mainBaseURI = mainBaseURI;
        nftLevel.genesisBaseURI = genesisBaseURI;

        /// @dev mainNftAmount and genesisNftAmount are set to 0 by default

        emit LevelDataSet(
            level,
            price,
            vestingRewards,
            lifecycleTimestamp,
            lifecycleExtensionTimestamp,
            allocationPerProject,
            mainBaseURI,
            genesisBaseURI
        );
    }

    /**
     * @notice  Sets accessible project amounts for each defined project in a level
     * @param   level  level, for which project data is being set
     * @param   project  project type (0 - Standard, 1 - Premium, 2- Limited)
     * @param   projectsQuantityInLifecycle  how many projects are going to
     * be accessible for its type and level
     */
    function setProjectsQuantity(
        uint16 level,
        uint8 project,
        uint16 projectsQuantityInLifecycle
    ) public onlyRole(DEFAULT_ADMIN_ROLE) mValidLevel(level) {
        // @question: should we check if the project type is valid?

        // Effects: set the projects quantity
        s_projectsPerNft[level][project] = projectsQuantityInLifecycle;

        emit ProjectsQuantityInLifecycleSet(
            level,
            project,
            projectsQuantityInLifecycle
        );
    }

    /**
     * @notice  Sets multiple accessible project amounts for a project in all levels
     * @param   project  project type (0 - Standard, 1 - Premium, 2- Limited)
     * @param   projectsQuantityInLifecycle  how many multiple projects are going to
     * be accessible for its type and level
     */
    function setMultipleProjectsQuantity(
        uint8 project,
        uint16[] memory projectsQuantityInLifecycle
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: the length of the array must be equal to the max level
        if (projectsQuantityInLifecycle.length != s_maxLevel) {
            revert Errors.Nft__MismatchInVariableLength();
        }

        // Valid levels are from 1 to maxLevel
        for (uint16 level = 1; level <= s_maxLevel; level++) {
            setProjectsQuantity(
                level,
                project,
                projectsQuantityInLifecycle[level - 1]
            );
        }
    }

    /**
     * @notice  Sets the new vesting contract address
     * @param   newContract  new vesting contract address
     */
    function setVestingContract(
        IVesting newContract
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAddressNotZero(address(newContract))
    {
        // Effects: set the new vesting contract
        s_vestingContract = newContract;

        emit VestingContractSet(newContract);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Returns the Nft data for a given token ID
     * @param   tokenId  id of the Nft
     * @return  NftData  Nft data
     */
    function getNftData(
        uint256 tokenId
    ) external view returns (NftData memory) {
        return s_nftData[tokenId];
    }

    /**
     * @notice  Returns the level data for a given level
     * @param   level  level of the Nft
     * @return  NftLevel  level data
     */
    function getLevelData(
        uint16 level
    ) external view returns (NftLevel memory) {
        return s_nftLevels[level];
    }

    /**
     * @notice  Returns the next token ID that will be minted
     * @return  uint256  next token ID
     */
    function getNextTokenId() external view returns (uint256) {
        return s_nextTokenId;
    }

    /**
     * @notice  Returns the max level that can be minted
     * @return  uint16  max level
     */
    function getMaxLevel() external view returns (uint16) {
        return s_maxLevel;
    }

    /**
     * @notice  Returns the genesis token divisor used for rewards calculation
     * @return  uint256  genesis token divisor
     */
    function getGenesisTokenDivisor() external view returns (uint256) {
        return s_genesisTokenDivisor;
    }

    /**
     * @notice  Returns the promotional vesting pool ID used for rewards distribution
     * @return  uint16  promotional vesting pool ID
     */
    function getPromotionalPID() external view returns (uint16) {
        return s_promotionalVestingPID;
    }

    /**
     * @notice  Returns the amount of projects that are accessible for a given level
     * @param   level  level of the Nft
     * @param   project  project type (0 - Standard, 1 - Premium, 2- Limited)
     * @return  uint16  amount of projects
     */
    function getProjectsQuantity(
        uint16 level,
        uint8 project
    ) external view returns (uint16) {
        return s_projectsPerNft[level][project];
    }

    /**
     * @notice  Returns the vesting contract address
     * @return  IVesting  vesting contract address
     */
    function getVestingContract() external view returns (IVesting) {
        return s_vestingContract;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INHERITED OVERRIDEN FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Transfers Nft from one user to another
     * @notice  User must be whitelisted to transfer Nft
     * @param   from  user who owns the Nft
     * @param   to  user who will get the Nft
     * @param   tokenId  id of the Nft
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(INft, IERC721, ERC721Upgradeable)
        onlyRole(WHITELISTED_SENDER_ROLE)
    {
        ERC721Upgradeable.transferFrom(from, to, tokenId);
    }

    function ownerOf(
        uint256 tokenId
    ) public view override(INft, IERC721, ERC721Upgradeable) returns (address) {
        return _requireOwned(tokenId);
    }

    /// @dev The following functions are overrides required by Solidity.

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            INft,
            ERC721Upgradeable,
            ERC721URIStorageUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR UPGRADER ROLE
    //////////////////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    uint256[50] private __gap; // @question Why are we adding this at the end?
}
