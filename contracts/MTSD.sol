// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma abicoder v2;

import "./libraries/TransferHelper.sol";
import "./interface/IERC20.sol";
import "./ERC20.sol";
import "./utils/SafeERC20.sol";
import "./upgrade/utils/UUPSUpgradeable.sol";
import "./access/OwnableUpgradeable.sol";
import "./upgrade/utils/Initializable.sol";
import "./access/AccessControlEnumerableUpgradeable.sol";

contract MTSD is
    Initializable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC20
{
    struct Pool {
        uint256 firstUnlockAmount;
        uint256 startBlock;
        uint256 cliff;
        uint256 vestingAmount;
        uint256 vestingRelaseRate;
        uint256 vestDuration;
        uint256 persionTotalAmount;
        uint256 released;
        address[] beneficiaries;
    }

    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** 18);

    //TREASURY 16.3%
    uint256 public constant TREASURY = (1000000000 * (10 ** 18) * 163) / 1000;

    // TEAM 12.7%
    uint256 public constant TEAM = (1000000000 * (10 ** 18) * 127) / 1000;

    // COMMUNITY 25%
    uint256 public constant COMMUNITY = (1000000000 * (10 ** 18) * 250) / 1000;
    // 16%
    uint256 public constant PRIVATE_SALE =
        (1000000000 * (10 ** 18) * 60) / 1000;

    uint256 public constant SEED_ROUND = (1000000000 * (10 ** 18) * 30) / 1000;

    uint256 public constant IAO = (1000000000 * (10 ** 18) * 70) / 1000;
    // ecosystem 30%
    uint256 public constant ECOSYSTEM = (1000000000 * (10 ** 18) * 300) / 1000;

    // bytes32 public constant DEFAULT_OP_ROLE = keccak256("DEFAULT_OP_ROLE");
    // bytes32 public constant DEFAULT_FINANCIAL_ROLE =keccak256("DEFAULT_FINANCIAL_ROLE");
    //合约启动后初始化
    uint16 public constant PRIVATE_SALE_KEY = 0x3571;
    uint16 public constant SEED_ROUND_KEY = 0x4c53;
    uint16 public constant IAO_KEY = 0x311d;

    uint256 public constant month = 30 days / 15; // 15s per block
    uint256 private constant day = 1 days / 15; // 15s per block

    //合约一起启动
    uint16 public constant TREASURY_KEY = 0x06aa;
    uint16 public constant TEAM_KEY = 0x9b82;
    uint16 public constant COMMUNITY_KEY = 0xe94d;
    uint16 public constant ECOSYSTEM_KEY = 0x016a;

    mapping(uint16 => address[]) public poolAddresses;

    mapping(uint16 => Pool) public pools;
    // encodePacked(uint16, address)
    mapping(bytes32 => uint256) public vestingBalances;

    // mapping(address => uint256) public claimedBalances;

    event StartSeedRound(
        uint256 startBlock,
        uint256 createBlock,
        address[] users
    );
    event StartPrivateSale(
        uint256 startBlock,
        uint256 createBlock,
        address[] users
    );
    event StartIAO(uint256 startBlock, uint256 createBlock, address[] users);
    event ClaimEvent(
        uint16 key,
        address account,
        uint256 amount,
        uint blockNumber
    );

    function startNoLinerPool(
        uint256 startBlock
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(startBlock >= block.number, "s0");
        createCommonmPool(TREASURY_KEY,startBlock,TREASURY);
             createCommonmPool(ECOSYSTEM_KEY,startBlock,ECOSYSTEM);
               createCommonmPool(COMMUNITY_KEY,startBlock,COMMUNITY);
        createTeamPool(startBlock);
    }

    function startActive(
        uint key,
        uint256 startBlock,
        address[] memory users
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            startBlock >= block.number,
            "firstUnlock must be greater than block.timestamp"
        );
        require(users.length > 0, "users is empty");
        if (key == 1) {
            createSeedRoundPool(startBlock, users);
            emit StartSeedRound(startBlock, block.number, users);
        } else if (key == 2) {
            createPrivateSalePool(startBlock, users);
            emit StartPrivateSale(startBlock, block.number, users);
        } else if (key == 3) {
            createIAOPool(startBlock, users);
            emit StartIAO(startBlock, block.number, users);
        } else {
            revert("invalid key");
        }
    }

    function pendingsWithAmount(
        address account
    ) external view returns (uint256 amount) {
        uint16[7] memory keys = [
            TREASURY_KEY,
            TEAM_KEY,
            COMMUNITY_KEY,
            ECOSYSTEM_KEY,
            PRIVATE_SALE_KEY,
            SEED_ROUND_KEY,
            IAO_KEY
        ];
        amount = 0;
        for (uint16 i = 0; i < 7; i++) {
            amount += pending(account, keys[i]);
        }
    }

    function pending(
        address account,
        uint16 key
    ) public view returns (uint256 amount) {
        bytes32 addressKey = keccak256(abi.encodePacked(key, account));
        return calculCurrentRelease(key, addressKey);
    }

    function queryOwnPool(
        address account
    ) external view returns (uint16[] memory ownKeys) {
        uint16[7] memory keys = [
            TREASURY_KEY,
            TEAM_KEY,
            COMMUNITY_KEY,
            ECOSYSTEM_KEY,
            PRIVATE_SALE_KEY,
            SEED_ROUND_KEY,
            IAO_KEY
        ];
        uint16 index = 0;
        for (uint256 i = 0; i < keys.length; i++) {
            if (
                poolAddresses[keys[i]].length > 0 &&
                poolContain(poolAddresses[keys[i]], account)
            ) {
                ownKeys[index] = keys[i];
                index++;
            }
        }
    }

    function poolContain(
        address[] memory users,
        address account
    ) private pure returns (bool) {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == account) {
                return true;
            }
        }
        return false;
    }

    function createIAOPool(uint256 startBlock, address[] memory users) private {
        Pool storage pool = pools[IAO_KEY];
        if (pool.startBlock > 0) {
            revert("i3");
        }
        poolAddresses[IAO_KEY] = users;
        pool.startBlock = startBlock;
        pool.firstUnlockAmount = (IAO * 25) / 100;
        pool.cliff = 3 * month;
        pool.vestingRelaseRate = (IAO * 75) / 100 / 24 / month;
        pool.vestingAmount = (IAO * 75) / 100;
        pool.released = 0;
        pool.vestDuration = 24 * month;
        pool.persionTotalAmount = IAO / users.length;
        pool.beneficiaries = poolAddresses[IAO_KEY];
    }

    function createPrivateSalePool(
        uint256 startBlock,
        address[] memory users
    ) private {
        Pool storage pool = pools[PRIVATE_SALE_KEY];
        if (pool.startBlock > 0) {
            revert("i2");
        }
        poolAddresses[PRIVATE_SALE_KEY] = users;
        pool.startBlock = startBlock;
        pool.firstUnlockAmount = (PRIVATE_SALE * 20) / 100;
        pool.cliff = 3 * month; //3 month
        pool.vestingRelaseRate = (PRIVATE_SALE * 80) / 100 / 24 /month;
        pool.vestingAmount = (PRIVATE_SALE * 80) / 100;
        pool.released = 0;
        pool.vestDuration = 24 * month;
        pool.persionTotalAmount = PRIVATE_SALE / users.length;
        pool.beneficiaries = poolAddresses[PRIVATE_SALE_KEY];
    }

    function createSeedRoundPool(
        uint256 startBlock,
        address[] memory users
    ) private {
        Pool storage pool = pools[SEED_ROUND_KEY];
        if (pool.startBlock > 0) {
            revert("i1");
        }
        poolAddresses[SEED_ROUND_KEY] = users;
        pool.startBlock = startBlock;
        pool.firstUnlockAmount = (SEED_ROUND * 20) / 100;
        pool.cliff = 6 * month;
        pool.vestingRelaseRate = (SEED_ROUND * 80) / 100 / 24 / month;
        pool.vestingAmount = (SEED_ROUND * 80) / 100;
        pool.persionTotalAmount = SEED_ROUND / users.length;
        pool.vestDuration = 24 * month;
        pool.released = 0;
        pool.beneficiaries = poolAddresses[SEED_ROUND_KEY];
    }

    function createTeamPool(uint256 startBlock) private {
        Pool storage pool = pools[TEAM_KEY];
        if (pool.startBlock > 0) {
            revert("a3");
        }
        pool.startBlock = startBlock;
        pool.firstUnlockAmount = (TEAM * 5) / 100;
        pool.cliff = 6 * month;
        pool.vestingRelaseRate = (TEAM * 95) / 100 / 60 / month;
        pool.vestingAmount = (TEAM * 95) / 100;
        pool.released = 0;
        pool.vestDuration = 60 * month;
        pool.beneficiaries = poolAddresses[TEAM_KEY];
        pool.persionTotalAmount = TEAM / pool.beneficiaries.length;
    }

    function claimReward(uint16[] memory ownKeys) external {
        require(isValidKeys(ownKeys), "invalid key");
        for (uint256 i = 0; i < ownKeys.length; i++) {
            if (
                poolAddresses[ownKeys[i]].length == 0 ||
                !poolContain(poolAddresses[ownKeys[i]], _msgSender())
            ) {
                continue;
            }
            claim(ownKeys[i]);
        }
    }

    function getPoolAddresses(
        uint16 key
    ) external view returns (address[] memory) {
        return poolAddresses[key];
    }

    function calculCurrentRelease(
        uint16 key,
        bytes32 addressKey
    ) private view returns (uint256) {
        Pool storage pool = pools[key];
        if (pool.startBlock > block.number) {
            return 0;
        }
        if (pool.released == pool.vestingAmount + pool.firstUnlockAmount) {
            return 0;
        }
        if (pool.beneficiaries.length == 0) {
            return 0;
        }
        uint256 withdrawAmounted = vestingBalances[addressKey];
        if (
            pool.persionTotalAmount != 0 &&
            withdrawAmounted >= pool.persionTotalAmount
        ) {
            return 0;
        }
        return remainUnclaimed(pool, withdrawAmounted);
    }
    function remainUnclaimed(
        Pool memory pool,
        uint256 withdrawAmounted
    ) private view returns (uint256) {
        if (pool.vestingRelaseRate == 0 || ( pool.cliff > 0 && block.number <= pool.startBlock + pool.cliff)) {
           return  pool.persionTotalAmount - withdrawAmounted;
        } else {
                uint256 amountPerBeneficiary = pool.vestingRelaseRate /
                pool.beneficiaries.length;
          if (
            pool.vestDuration > 0 &&
            pool.startBlock + pool.cliff + pool.vestDuration < block.number
            ) {
             return  pool.firstUnlockAmount/pool.beneficiaries.length +
                pool.vestingAmount/pool.beneficiaries.length -
                withdrawAmounted;
      
            }else{
                return pool.firstUnlockAmount /
                pool.beneficiaries.length +
                (block.number - pool.startBlock - pool.cliff) *
                amountPerBeneficiary -
                withdrawAmounted;
            }

        }
    }

    function claim(uint16 key) private {
        bytes32 addressKey = keccak256(abi.encodePacked(key, _msgSender()));
        uint256 amount = calculCurrentRelease(key, addressKey);
        if (amount <= 0) {
            return;
        }
               vestingBalances[addressKey] +=  amount;
                pools[key].released += amount;
               TransferHelper.safeTransfer(address(this), _msgSender(), amount);
        emit ClaimEvent(key, _msgSender(), amount, block.number);
    }

    //the next is init with startBlock

     function createCommonmPool(uint16 key,uint256 startBlock,uint256 amount) private {
        Pool storage pool = pools[key];
        if (pool.startBlock > 0) {
            revert("a1");
        }
        pool.startBlock = startBlock;
        pool.firstUnlockAmount = amount;
        pool.cliff = 0;
        pool.vestingAmount = 0;
        pool.vestingRelaseRate = 0;
        pool.released = 0;
        pool.beneficiaries = poolAddresses[key];
        pool.persionTotalAmount = amount / pool.beneficiaries.length;
    }



    function isValidKeys(uint16[] memory keys) private pure returns (bool) {
        for (uint256 i = 0; i < keys.length; i++) {
            if (!isValidKey(keys[i])) {
                return false;
            }
        }
        return true;
    }

    function isValidKey(uint16 key) private pure returns (bool) {
        return
            key == TREASURY_KEY ||
            key == TEAM_KEY ||
            key == COMMUNITY_KEY ||
            key == ECOSYSTEM_KEY ||
            key == PRIVATE_SALE_KEY ||
            key == SEED_ROUND_KEY ||
            key == IAO_KEY;
    }

    function isAddableKey(uint16 key) private pure returns (bool) {
        return
            key == PRIVATE_SALE_KEY || key == SEED_ROUND_KEY || key == IAO_KEY;
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __AccessControlEnumerable_init();
        __ERC20_init("MTSD", INITIAL_SUPPLY, address(this));
        mtsd_init_unchained();
    }

    function mtsd_init_unchained() internal onlyInitializing {
        // _setRoleAdmin(DEFAULT_OP_ROLE, DEFAULT_ADMIN_ROLE);
        // _setRoleAdmin(DEFAULT_FINANCIAL_ROLE, DEFAULT_ADMIN_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // _grantRole(DEFAULT_OP_ROLE, _msgSender());
        // _grantRole(DEFAULT_FINANCIAL_ROLE, _msgSender());
        setPool();
    }

    function setPool() private {
        poolAddresses[TREASURY_KEY] = [
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            0x976EA74026E726554dB657fA54763abd0C3a0aa9
        ];
        poolAddresses[TEAM_KEY] = [
            0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
            0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f
        ];
        poolAddresses[COMMUNITY_KEY] = [
            0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
        ];
        poolAddresses[ECOSYSTEM_KEY] = [
            0x90F79bf6EB2c4f870365E785982E1f101E93b906
        ];
    }

    // function addOp(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    //     grantRole(DEFAULT_OP_ROLE, account);
    // }

    function addAmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    // function addFinancial(
    //     address account
    // ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    //     grantRole(DEFAULT_FINANCIAL_ROLE, account);
    // }

    // function removeOp(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    //     revokeRole(DEFAULT_OP_ROLE, account);
    // }

    function removeAmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    // function removeFinancial(
    //     address account
    // ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    //     revokeRole(DEFAULT_FINANCIAL_ROLE, account);
    // }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

     receive() external payable {
              revert("not support");
    }

  function callBack() external {
        revert("not support");
    }
}
