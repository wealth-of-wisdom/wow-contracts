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
    string private constant NFT_URI_SUFFIX = ".json";

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */

    mapping(uint256 tokenId => NftData nftData) internal s_nftData;

    // Hash = keccak256(level, isGenesis)
    mapping(bytes32 configHash => NftLevel levelData) internal s_nftLevels;

    // Hash = keccak256(level, isGenesis, project type number (0 - Standard, 1 - Premium, 2- Limited)))
    mapping(bytes32 configHash => uint16 quantity) internal s_projectsPerNft;

    // Map of current active NFT to its owner
    mapping(address owner => uint256 tokenId) internal s_activeNft;

    uint256 internal s_nextTokenId;

    IVesting internal s_vestingContract;

    uint16 internal s_maxLevel;

    uint16 internal s_promotionalVestingPID;

    uint8 internal s_totalProjectTypes; // Standard, Premium, Limited

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
        uint16 promotionalVestingPID,
        uint16 maxLevel,
        uint8 totalProjectTypes
    )
        external
        initializer
        mAmountNotZero(maxLevel)
        mAmountNotZero(totalProjectTypes)
    {
        /// @dev no validation for vestingContract is needed,
        /// @dev because if it is zero, the contract will limit some functionality

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
        s_promotionalVestingPID = promotionalVestingPID;
        s_maxLevel = maxLevel;
        s_totalProjectTypes = totalProjectTypes;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR ALL USERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Sets Nft data state as ACTIVATION_TRIGGERED,
     * @notice  manages other data about the Nft and adds its holder to vesting pool
     * @param   tokenId  user minted and owned token id
     */
    function activateNftData(
        uint256 tokenId,
        bool isSettingVestingRewards
    ) external {
        _activateNftData(tokenId, isSettingVestingRewards, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        FUNCTIONS FOR NFT DATA MANAGER ROLE
    //////////////////////////////////////////////////////////////////////////*/

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
    )
        external
        onlyRole(NFT_DATA_MANAGER_ROLE)
        onlyRole(MINTER_ROLE)
        returns (uint256 tokenId)
    {
        tokenId = s_nextTokenId;

        // Effects: set nft data with next token id
        setNftData(
            tokenId,
            level,
            isGenesis,
            INft.ActivityType.NOT_ACTIVATED,
            0,
            0
        );

        // Effects: mint the token and set metadata URI
        safeMint(receiver, level, isGenesis);

        emit MintedAndSetNftData(receiver, level, isGenesis, tokenId);
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
    ) external onlyRole(NFT_DATA_MANAGER_ROLE) onlyRole(MINTER_ROLE) {
        // Checks: old token must be owned by the receiver
        if (ownerOf(oldTokenId) != receiver) {
            revert Errors.Nft__ReceiverNotOwner();
        }

        // Checks: old token cannot be genesis
        if (s_nftData[oldTokenId].isGenesis) {
            revert Errors.Nft__GenesisNftNotUpdatable();
        }

        uint256 newTokenId = s_nextTokenId;

        // Effects: Update the active NFT for the sender
        if (
            s_activeNft[receiver] == oldTokenId &&
            s_nftData[oldTokenId].activityType ==
            ActivityType.ACTIVATION_TRIGGERED
        ) {
            delete s_activeNft[receiver];

            emit ActiveNftUpdated(receiver, 0);
        }

        // Effects: deactivate the old NFT
        s_nftData[oldTokenId].activityType = ActivityType.DEACTIVATED;

        emit NftDeactivated(oldTokenId);

        // Effects: set nft data with next token id
        setNftData(
            newTokenId,
            newLevel,
            false,
            INft.ActivityType.NOT_ACTIVATED,
            0,
            0
        );

        // Effects: mint the token and set metadata URI
        safeMint(receiver, newLevel, false);

        emit NftUpdated(receiver, newLevel, oldTokenId, newTokenId);
    }

    /**
     * @notice  sets all necesary information about the users Nft and its current state
     * @param   tokenId  user minted and owned token id
     * @param   level  nft level purchased
     * @param   isGenesis  is it a genesis nft
     * @param   activityType  activity state of the Nft
     * @param   activityEndTimestamp  Nft regular expiration date
     * @param   extendedActivityEndTimestamp  Nft extended expiration date
     */
    /* solhint-disable ordering */
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

    /* solhint-enable */

    /*//////////////////////////////////////////////////////////////////////////
                        FUNCTIONS FOR DEFAULT ADMIN ROLE
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Mints Nft to user with defined level, type and token Id
     * @notice  Sets the token URI using the base URI and pre defined token Id
     * @dev     Only MINTER_ROLE can call this function
     * @param   to  user who will get the Nft
     * @param   level  nft level purchased
     * @param   isGenesis  is it a genesis nft
     * @param   tokenId  id that is going to be minted
     */
    /* solhint-disable ordering */
    function safeMintWithTokenId(
        address to,
        uint16 level,
        bool isGenesis,
        uint256 tokenId
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAddressNotZero(to)
        mValidLevel(level)
    {
        _safeMint(to, level, isGenesis, tokenId);
    }

    /**
     * @notice  set the token metadata URI (URI for each token is assigned before minting)
     * @param   tokenId  user minted and owned token id
     * @param   _tokenURI  metadata link
     */
    function setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenURI(tokenId, _tokenURI);
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
        uint256 supplyCap,
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

        // Checks: the amount of NFTs minted must not exceed the max supply
        if (supplyCap < nftLevel.nftAmount) {
            revert Errors.Nft__SupplyCapTooLow(supplyCap);
        }

        nftLevel.price = price;
        nftLevel.vestingRewardWOWTokens = vestingRewards;
        nftLevel.lifecycleDuration = lifecycleDuration;
        nftLevel.extensionDuration = extensionDuration;
        nftLevel.allocationPerProject = allocationPerProject;
        nftLevel.supplyCap = supplyCap;
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
            supplyCap,
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
    /* solhint-disable ordering */
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

    /* solhint-enable */

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
     * @notice  Sets active user nft with new id
     * @param   user  wallet address of user
     * @param   newId id replacing old active nft id
     */
    function setActiveNft(
        address user,
        uint256 newId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Effects: set active user nft
        s_activeNft[user] = newId;

        emit ActiveNftSet(user, newId);
    }

    /**
     * @notice  Sets the new vesting contract address
     * @param   newContract  new vesting contract address
     */
    function setVestingContract(
        IVesting newContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Effects: set the new vesting contract
        s_vestingContract = newContract;

        emit VestingContractSet(newContract);
    }

    /**
     * @notice  Sets next token Id in emergencies (after minting with specific token Id)
     * @param   nextTokenId  new next token Id
     */
    function setNextTokenId(
        uint256 nextTokenId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // Effects: set the new next token Id
        s_nextTokenId = nextTokenId;

        emit NextTokenIdSet(nextTokenId);
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
    /* solhint-disable ordering */
    function safeMint(
        address to,
        uint16 level,
        bool isGenesis
    ) public onlyRole(MINTER_ROLE) mAddressNotZero(to) mValidLevel(level) {
        // Effects: increment the token id
        // tokenId is assigned prior to incrementing the token id, so it starts from 0
        uint256 tokenId = s_nextTokenId++;

        // Effects: mint the token and set metadata URI
        _safeMint(to, level, isGenesis, tokenId);
    }

    /* solhint-enable */

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
     * @notice  Returns activated NFT for owner
     * @return  address  token owner
     */
    function getActiveNft(address owner) external view returns (uint256) {
        return s_activeNft[owner];
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
        uint256 senderActiveNftId = s_activeNft[from];
        uint256 receiverActiveNftId = s_activeNft[to];

        // Checks: The nft that is being transferred is active one
        if (
            _ownerOf(senderActiveNftId) == from &&
            s_nftData[senderActiveNftId].activityType ==
            ActivityType.ACTIVATION_TRIGGERED &&
            tokenId == senderActiveNftId
        ) {
            // Checks: user must not own an active NFT
            // We check the ownership because the nft id can be 0 (which is default value)
            if (
                _ownerOf(receiverActiveNftId) == to &&
                s_nftData[receiverActiveNftId].activityType ==
                ActivityType.ACTIVATION_TRIGGERED
            ) {
                revert Errors.Nft__UserOwnsActiveNft();
            }

            // Effects: Update the active NFT for the sender
            delete s_activeNft[from];

            emit ActiveNftUpdated(from, 0);

            // Effects: Update the active NFT for the receiver
            s_activeNft[to] = tokenId;

            emit ActiveNftUpdated(to, tokenId);
        }
        // Else if nft is not active, we can transfer it without any additional checks

        // Effects: transfer the token from one user to another
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

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    /* solhint-enable */

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

    function _safeMint(
        address to,
        uint16 level,
        bool isGenesis,
        uint256 tokenId
    ) internal onlyRole(MINTER_ROLE) mAddressNotZero(to) mValidLevel(level) {
        NftLevel storage nftLevel = s_nftLevels[
            _getLevelHash(level, isGenesis)
        ];

        uint256 nftAmount = nftLevel.nftAmount;

        // Checks: the amount of NFTs minted must not exceed the max supply
        if (!isGenesis && nftAmount >= nftLevel.supplyCap) {
            revert Errors.Nft__SupplyCapReached(level, isGenesis, nftAmount);
        }

        // Effects: mint the token
        _safeMint(to, tokenId);

        // Effects: increment the token quantity in the level
        nftLevel.nftAmount++;

        emit NftMinted(to, tokenId, level, isGenesis, nftAmount);

        // Concatenate base URI, id in level and suffix to get the full URI
        string memory uri = string.concat(
            nftLevel.baseURI,
            Strings.toString(nftAmount),
            NFT_URI_SUFFIX
        );

        // Effects: set the token metadata URI (URI for each token is assigned before minting)
        _setTokenURI(tokenId, uri);

        if (isGenesis) {
            _activateNftData(tokenId, false, to);
        }
    }

    /**
     * @notice  Sets Nft data state as ACTIVATION_TRIGGERED,
     * @notice  manages other data about the Nft and adds its holder to vesting pool
     * @param   tokenId  user minted and owned token id
     * @param   isSettingVestingRewards  should it set vesting rewards automatically
     * @param   user  user whose Nft will be activated
     */
    function _activateNftData(
        uint256 tokenId,
        bool isSettingVestingRewards,
        address user
    ) public {
        // Checks: sender must be the owner of the Nft
        if (ownerOf(tokenId) != user) {
            revert Errors.Nft__NotNftOwner();
        }

        NftData storage newNftData = s_nftData[tokenId];
        NftLevel storage levelData = s_nftLevels[
            _getLevelHash(newNftData.level, newNftData.isGenesis)
        ];
        uint256 activeNftId = s_activeNft[user];
        NftData storage oldNftData = s_nftData[activeNftId];

        // Checks: data must not be activated
        if (newNftData.activityType != ActivityType.NOT_ACTIVATED) {
            revert Errors.Nft__AlreadyActivated();
        }

        // Checks: only deactivate nfts that are activated and owned by the user
        if (
            _ownerOf(activeNftId) == user &&
            oldNftData.activityType == ActivityType.ACTIVATION_TRIGGERED
        ) {
            oldNftData.activityType = ActivityType.DEACTIVATED;
            emit NftDeactivated(activeNftId);
        }

        s_activeNft[user] = tokenId;

        emit ActiveNftUpdated(user, tokenId);

        // Effects: update nft data
        newNftData.activityType = ActivityType.ACTIVATION_TRIGGERED;
        newNftData.activityEndTimestamp =
            block.timestamp +
            levelData.lifecycleDuration;
        newNftData.extendedActivityEndTimestamp =
            newNftData.activityEndTimestamp +
            levelData.extensionDuration;

        if (isSettingVestingRewards) {
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
                    user,
                    rewardTokens
                );
            }
        }

        emit NftDataActivated(
            user,
            tokenId,
            newNftData.level,
            newNftData.isGenesis,
            newNftData.activityEndTimestamp,
            newNftData.extendedActivityEndTimestamp
        );
    }
}
