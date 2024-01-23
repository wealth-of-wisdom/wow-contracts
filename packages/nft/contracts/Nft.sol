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
    uint16 public constant LEVEL_5 = 5;

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */
    mapping(uint256 tokenId => NftData nftData) internal s_nftData;

    // Hash = keccak256(level, isGenesis)
    mapping(bytes32 configHash => NftLevel levelData) internal s_nftLevels;

    // Hash = keccak256(level, isGenesis, project type number (0 - Standard, 1 - Premium, 2- Limited)))
    mapping(bytes32 configHash => uint16 quantity) internal s_projectsPerNft;

    uint256 internal s_nextTokenId;
    uint256 internal s_level5SupplyCap;
    uint8 internal s_totalProjectTypes; // Standard, Premium, Limited
    uint16 internal s_maxLevel;
    uint16 internal s_promotionalVestingPID;

    IVesting internal s_vestingContract;

    /* solhint-enable */

    /*//////////////////////////////////////////////////////////////////////////
                            STORAGE FOR FUTURE UPGRADES
    //////////////////////////////////////////////////////////////////////////*/

    uint256[50] private __gap;

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
     */
    function initialize(
        string memory name,
        string memory symbol,
        IVesting vestingContract,
        uint256 level5SupplyCap,
        uint16 promotionalVestingPID,
        uint16 maxLevel,
        uint8 totalProjectTypes
    )
        external
        initializer
        mAddressNotZero(address(vestingContract))
        mAmountNotZero(maxLevel)
        mAmountNotZero(totalProjectTypes)
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
        s_level5SupplyCap = level5SupplyCap;
        s_promotionalVestingPID = promotionalVestingPID;
        s_maxLevel = maxLevel;
        s_totalProjectTypes = totalProjectTypes;
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
        NftLevel storage nftLevel = s_nftLevels[
            _getLevelHash(level, isGenesis)
        ];

        uint256 nftAmount = nftLevel.nftAmount;

        // Checks: the amount of NFTs minted must not exceed the max supply
        if (level == LEVEL_5 && !isGenesis && nftAmount >= s_level5SupplyCap) {
            revert Errors.Nft__SupplyCapReached(level, isGenesis, nftAmount);
        }

        // Effects: increment the token id
        // tokenId is assigned prior to incrementing the token id, so it starts from 0
        uint256 tokenId = s_nextTokenId++;

        // Effects: mint the token
        _safeMint(to, tokenId);

        // Effects: increment the token quantity in the level
        nftLevel.nftAmount++;

        // Concatenate base URI, id in level and suffix to get the full URI
        string memory uri = string.concat(
            nftLevel.baseURI,
            Strings.toString(nftAmount),
            NFT_URI_SUFFIX
        );

        // Effects: set the token metadata URI (URI for each token is assigned before minting)
        _setTokenURI(tokenId, uri);

        emit NftMinted(to, tokenId, level, isGenesis, nftAmount);
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
        NftLevel storage levelData = s_nftLevels[
            _getLevelHash(nftData.level, nftData.isGenesis)
        ];

        // Checks: data must not be activated
        if (nftData.activityType != ActivityType.NOT_ACTIVATED) {
            revert Errors.Nft__AlreadyActivated();
        }

        // Effects: update nft data
        nftData.activityType = ActivityType.ACTIVATION_TRIGGERED;
        nftData.activityEndTimestamp =
            block.timestamp +
            levelData.lifecycleDuration;
        nftData.extendedActivityEndTimestamp =
            nftData.activityEndTimestamp +
            levelData.extensionDuration;

        (
            ,
            ,
            uint256 totalPoolTokenAmount,
            uint256 dedicatedPoolTokenAmount
        ) = s_vestingContract.getGeneralPoolData(s_promotionalVestingPID);

        // Calculate the amount of tokens that can still be distributed
        uint256 undedicatedTokens = totalPoolTokenAmount -
            dedicatedPoolTokenAmount;

        if (undedicatedTokens > 0) {
            // Rewards are fixed for each level
            uint256 rewardTokens = levelData.vestingRewardWOWTokens;

            // If there are enough tokens, then the reward is vestingRewardWOWTokens
            // Otherwise, the reward is the amount of tokens that can still be distributed
            if (undedicatedTokens < rewardTokens) {
                rewardTokens = undedicatedTokens;
            }

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
     * @notice  sets all necesary information about the users Nft and its current state
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

    function setLevel5SupplyCap(
        uint256 newCap
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        NftLevel storage nftLevel5 = s_nftLevels[_getLevelHash(LEVEL_5, false)];
        uint256 nftAmount = nftLevel5.nftAmount;

        // Checks: the amount of NFTs minted must not exceed the max supply
        if (newCap < nftAmount) {
            revert Errors.Nft__SupplyCapTooLow(newCap);
        }

        // Effects: set the new max supply
        s_level5SupplyCap = newCap;

        emit Level5SupplyCapSet(newCap);
    }

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

    function setTotalProjectTypes(
        uint8 newCount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: the new project types count must be greater than the current project types count
        if (newCount <= s_totalProjectTypes) {
            revert Errors.Nft__InvalidTotalProjectTypes(newCount);
        }

        // Effects: set the new project types count
        s_totalProjectTypes = newCount;

        emit TotalProjectTypesSet(newCount);
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
     * @param   isGenesis  is it a genesis Nft
     * @param   price  price of the Nft in USDT/USDC
     * @param   vestingRewards  amount of WOW tokens that will be locked into the vesting pool
     * @param   lifecycleDuration  duration of the lifecycle
     * @param   extensionDuration  duration of the lifecycle extension
     * @param   allocationPerProject  allocation per project in USDT/USDC
     * @param   baseURI  base URI for the main NFT
     */
    function setLevelData(
        uint16 level,
        bool isGenesis,
        uint256 price,
        uint256 vestingRewards,
        uint256 lifecycleDuration,
        uint256 extensionDuration,
        uint256 allocationPerProject,
        string calldata baseURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: level must be valid
        if (level == 0 || level > s_maxLevel) {
            revert Errors.Nft__InvalidLevel(level);
        }

        // Checks: amounts must be greater than 0
        if (price == 0 || lifecycleDuration == 0) {
            revert Errors.Nft__ZeroAmount();
        }

        // Checks: base URIs must not be empty
        if (bytes(baseURI).length == 0) {
            revert Errors.Nft__EmptyString();
        }

        // Effects: set level data
        NftLevel storage nftLevel = s_nftLevels[
            _getLevelHash(level, isGenesis)
        ];

        nftLevel.price = price;
        nftLevel.vestingRewardWOWTokens = vestingRewards;
        nftLevel.lifecycleDuration = lifecycleDuration;
        nftLevel.extensionDuration = extensionDuration;
        nftLevel.allocationPerProject = allocationPerProject;
        nftLevel.baseURI = baseURI;

        /// @dev nftAmount should not be set here, because it is incremented when minting

        emit LevelDataSet(
            level,
            isGenesis,
            price,
            vestingRewards,
            lifecycleDuration,
            extensionDuration,
            allocationPerProject,
            baseURI
        );
    }

    /**
     * @notice  Sets accessible project amounts for each defined project in a level
     * @param   level  level, for which project data is being set
     * @param   project  project type (0 - Standard, 1 - Premium, 2- Limited)
     * @param   quantity  how many projects are going to
     * be accessible for its type and level
     */
    function setProjectsQuantity(
        uint16 level,
        bool isGenesis,
        uint8 project,
        uint16 quantity
    ) public onlyRole(DEFAULT_ADMIN_ROLE) mValidLevel(level) {
        // Checks: project must not overflow the total project types count
        if (project >= s_totalProjectTypes) {
            revert Errors.Nft__InvalidProjectType(project);
        }

        // Effects: set the projects quantity
        s_projectsPerNft[_getProjectHash(level, isGenesis, project)] = quantity;

        emit ProjectsQuantitySet(level, isGenesis, project, quantity);
    }

    /**
     * @notice  Sets multiple accessible project amounts for a project in all levels
     * @param   project  project type (0 - Standard, 1 - Premium, 2- Limited)
     * @param   quantities  how many multiple projects are going to
     * be accessible for its type and level
     */
    function setMultipleProjectsQuantity(
        bool isGenesis,
        uint8 project,
        uint16[] memory quantities
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: the length of the array must be equal to the max level
        if (quantities.length != s_maxLevel) {
            revert Errors.Nft__MismatchInVariableLength();
        }

        // Valid levels are from 1 to maxLevel
        for (uint16 level = 1; level <= s_maxLevel; level++) {
            setProjectsQuantity(
                level,
                isGenesis,
                project,
                quantities[level - 1]
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
        uint16 level,
        bool isGenesis
    ) external view returns (NftLevel memory) {
        return s_nftLevels[_getLevelHash(level, isGenesis)];
    }

    /**
     * @notice  Returns the amount of projects that are accessible for a given level
     * @param   level  level of the Nft
     * @param   project  project type (0 - Standard, 1 - Premium, 2- Limited)
     * @return  uint16  amount of projects
     */
    function getProjectsQuantity(
        uint16 level,
        bool isGenesis,
        uint8 project
    ) external view returns (uint16) {
        return s_projectsPerNft[_getProjectHash(level, isGenesis, project)];
    }

    /**
     * @notice  Returns the next token ID that will be minted
     * @return  uint256  next token ID
     */
    function getNextTokenId() external view returns (uint256) {
        return s_nextTokenId;
    }

    /**
     * @notice  Returns the supply cap for level 5
     * @return  uint256 maximum tokens that can be minted for level 5
     */
    function getLevel5SupplyCap() external view returns (uint256) {
        return s_level5SupplyCap;
    }

    /**
     * @notice  Returns the max level that can be minted
     * @return  uint16  max level
     */
    function getMaxLevel() external view returns (uint16) {
        return s_maxLevel;
    }

    /**
     * @notice  Returns number of project types users can choose from
     * @return  uint256 total project types
     */
    function getTotalProjectTypes() external view returns (uint8) {
        return s_totalProjectTypes;
    }

    /**
     * @notice  Returns the promotional vesting pool ID used for rewards distribution
     * @return  uint16  promotional vesting pool ID
     */
    function getPromotionalPID() external view returns (uint16) {
        return s_promotionalVestingPID;
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
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
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

    /*//////////////////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _getLevelHash(
        uint16 level,
        bool isGenesis
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(level, isGenesis));
    }

    function _getProjectHash(
        uint16 level,
        bool isGenesis,
        uint8 project // 0 - Standard, 1 - Premium, 2- Limited
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(level, isGenesis, project));
    }
}
