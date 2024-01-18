// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {ERC721BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {INft} from "@wealth-of-wisdom/nft/contracts/interfaces/INft.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";

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
    bytes32 public constant NFT_DATA_MANAGER = keccak256("NFT_DATA_MANAGER");
    string private constant NFT_URI_SUFFIX = ".json";

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    IVesting internal s_vestingContract;

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */
    mapping(uint256 tokenId => NftData) internal s_nftData; // token ID => nft data
    mapping(uint16 level => NftLevel) internal s_nftLevels; // level => level data
    // level => project (Standard, Premium, Limited) => project amount
    mapping(uint16 level => mapping(uint16 project => uint16 projectAmount))
        internal s_projectsPerNft;
    uint16 internal s_maxLevel;
    uint16 internal s_promotionalVestingPID;
    uint256 internal s_genesisTokenDivisor;
    uint256 internal s_nextTokenId;

    /* solhint-enable */

    /*//////////////////////////////////////////////////////////////////////////
                                  MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier mAmountNotZero(uint256 amount) {
        if (amount == 0) {
            revert Errors.Nft__ZeroAmount();
        }
        _;
    }

    modifier mStringNotEmpty(string memory str) {
        if (bytes(str).length == 0) {
            revert Errors.Nft__EmptyString();
        }
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        IVesting vestingContract,
        uint16 maxLevel,
        uint16 promotionalVestingPID,
        uint256 genesisTokenDivisor
    ) external initializer mStringNotEmpty(name) mStringNotEmpty(symbol) {
        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(WHITELISTED_SENDER_ROLE, msg.sender);
        _grantRole(NFT_DATA_MANAGER, msg.sender);

        s_maxLevel = maxLevel;
        s_promotionalVestingPID = promotionalVestingPID;
        s_genesisTokenDivisor = genesisTokenDivisor;

        s_vestingContract = vestingContract;
    }

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
    ) public onlyRole(MINTER_ROLE) {
        // tokenId is assigned prior to incrementing the token id, so it starts from 0
        uint256 tokenId = s_nextTokenId++;
        _safeMint(to, tokenId);

        NftLevel storage nftLevel = s_nftLevels[level];

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

        // Set the token metadata URI (URI for each token is assigned before minting)
        _setTokenURI(tokenId, uri);
    }

    /**
     * @notice  sets Nft data state as ACTIVATION_TRIGGERED,
     * manages other data about the Nft and adds its holder to vesting pool
     * @param   tokenId  user minted and owned token id
     */
    function activateNftData(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) {
            revert Errors.Nft__NotNftOwner();
        }

        NftData memory nftData = s_nftData[tokenId];

        // Checks: data must not be activated
        if (nftData.activityType != ActivityType.NOT_ACTIVATED) {
            revert Errors.Nft__AlreadyActivated();
        }

        // Effects: update data activity
        nftData.activityType = ActivityType.ACTIVATION_TRIGGERED;
        nftData.activityEndTimestamp =
            block.timestamp +
            s_nftLevels[nftData.level].lifecycleTimestamp;
        nftData.extendedActivityEndTimestamp =
            nftData.activityEndTimestamp +
            s_nftLevels[nftData.level].lifecycleExtensionTimestamp;

        (
            ,
            ,
            uint256 totalPoolTokenAmount,
            uint256 dedicatedPoolTokenAmount
        ) = s_vestingContract.getGeneralPoolData(s_promotionalVestingPID);
        uint256 nonDedicatedTokens = totalPoolTokenAmount -
            dedicatedPoolTokenAmount;
        NftLevel memory nftLevelData = s_nftLevels[nftData.level];

        // example calculations:
        // 200k rewards = 40k WoW tokens * ( 5k price / 1k )
        // (40k tokens per 1k spent)
        uint256 rewardTokens = nftData.isGenesis
            ? nftLevelData.vestingRewardWOWTokens *
                (nftLevelData.price / s_genesisTokenDivisor)
            : nftLevelData.vestingRewardWOWTokens;

        rewardTokens = (nonDedicatedTokens < rewardTokens)
            ? nonDedicatedTokens
            : rewardTokens;

        if (rewardTokens > 0) {
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
            uint256(nftData.activityType),
            nftData.activityEndTimestamp
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR ADMIN ROLE
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
    ) public onlyRole(NFT_DATA_MANAGER) {
        s_nftData[tokenId] = NftData({
            level: level,
            isGenesis: isGenesis,
            activityType: activityType,
            activityEndTimestamp: activityEndTimestamp,
            extendedActivityEndTimestamp: extendedActivityEndTimestamp
        });
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
    ) external onlyRole(NFT_DATA_MANAGER) {
        setNftData(
            s_nextTokenId,
            level,
            isGenesis,
            INft.ActivityType.NOT_ACTIVATED,
            0,
            0
        );
        safeMint(receiver, level, isGenesis);
    }

    /**
     * @notice  updates data for old Nft token and new one.
     * Sets necesary states for upgrade - from one level to another
     * @param   receiver  user who will get the Nft
     * @param   oldTokenId  previously owned Nft id, which is being upgraded
     * @param   newLevel  level upgraded to
     */
    function updateLevelDataAndMint(
        address receiver,
        uint256 oldTokenId,
        uint16 newLevel
    ) external onlyRole(NFT_DATA_MANAGER) {
        s_nftData[oldTokenId].activityType = ActivityType.DEACTIVATED;

        setNftData(
            s_nextTokenId,
            newLevel,
            false,
            INft.ActivityType.NOT_ACTIVATED,
            0,
            0
        );
        safeMint(receiver, newLevel, false);
    }

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

    function setGenesisTokenDivisor(
        uint256 newGenesisTokenDivisor
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAmountNotZero(newGenesisTokenDivisor)
    {
        s_genesisTokenDivisor = newGenesisTokenDivisor;
        emit DivisorSet(newGenesisTokenDivisor);
    }

    function setPromotionalVestingPID(
        uint16 pid
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        s_promotionalVestingPID = pid;
        emit PromotionalVestingPIDSet(pid);
    }

    //NOTE: convert necesary lifecycle time into timestamp
    function setLevelData(
        uint16 level,
        uint256 price,
        uint256 vestingRewards,
        uint256 lifecycleTimestamp,
        uint256 lifecycleExtensionTimestamp,
        uint256 allocationPerProject,
        uint256 mainNftAmount,
        uint256 genesisNftAmount,
        string calldata mainBaseURI,
        string calldata genesisBaseURI
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAmountNotZero(price)
        mAmountNotZero(lifecycleTimestamp)
        mStringNotEmpty(mainBaseURI)
        mStringNotEmpty(genesisBaseURI)
    {
        s_nftLevels[level] = NftLevel({
            price: price,
            vestingRewardWOWTokens: vestingRewards,
            lifecycleTimestamp: lifecycleTimestamp,
            lifecycleExtensionTimestamp: lifecycleExtensionTimestamp,
            allocationPerProject: allocationPerProject,
            mainNftAmount: mainNftAmount,
            genesisNftAmount: genesisNftAmount,
            mainBaseURI: mainBaseURI,
            genesisBaseURI: genesisBaseURI
        });

        emit LevelDataSet(
            level,
            price,
            vestingRewards,
            lifecycleTimestamp,
            lifecycleExtensionTimestamp,
            allocationPerProject,
            mainNftAmount,
            genesisNftAmount,
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
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
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
        if (projectsQuantityInLifecycle.length != s_maxLevel)
            revert Errors.Nft__MismatchInVariableLength();
        for (uint16 level; level < s_maxLevel; level++) {
            s_projectsPerNft[level][project] = projectsQuantityInLifecycle[
                level
            ];
            emit ProjectsQuantityInLifecycleSet(
                level,
                project,
                projectsQuantityInLifecycle[level]
            );
        }
    }

    function setVestingContract(
        IVesting newContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(newContract) == address(0)) {
            revert Errors.Nft__ZeroAddress();
        }
        s_vestingContract = newContract;
        emit VestingContractSet(newContract);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getNftData(uint256 tokenId) public view returns (NftData memory) {
        return s_nftData[tokenId];
    }

    function getLevelData(uint16 level) public view returns (NftLevel memory) {
        return s_nftLevels[level];
    }

    function getNextTokenId() public view returns (uint256) {
        return s_nextTokenId;
    }

    function getMaxLevel() public view returns (uint16) {
        return s_maxLevel;
    }

    function getGenesisTokenDivisor() public view returns (uint256) {
        return s_genesisTokenDivisor;
    }

    function getPromotionalPID() public view returns (uint16) {
        return s_promotionalVestingPID;
    }

    function getProjectLifecycle(
        uint16 level,
        uint8 project
    ) public view returns (uint16) {
        return s_projectsPerNft[level][project];
    }

    function getVestingContract() external view returns (IVesting) {
        return s_vestingContract;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INHERITED OVERRIDEN FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, INft)
        onlyRole(WHITELISTED_SENDER_ROLE)
    {
        ERC721Upgradeable.transferFrom(from, to, tokenId);
    }

    function ownerOf(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, INft) returns (address) {
        return _requireOwned(tokenId);
    }

    // The following functions are overrides required by Solidity.

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
            ERC721Upgradeable,
            ERC721URIStorageUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    // The following functions are overrides required by Solidity.

    uint256[50] private __gap;
}
