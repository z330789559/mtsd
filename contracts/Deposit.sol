// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interface/IDeposit.sol";

import "./upgrade/utils/UUPSUpgradeable.sol";
import "./access/OwnableUpgradeable.sol";
import "./upgrade/utils/Initializable.sol";
import "./utils/CountersUpgradeable.sol";
import "./interface/IWalletManage.sol";
import "./utils/SafeERC20.sol";
/**
 资金管理合约
 包括以下功能 ： 充值 ，提取 ，运营管理，管理人员管理 管理员提取， 管理员提取手续费

充值： 先配置AddSuportToken 增加合约支持的token ,然后通过deposit 充值
   充值参数说明
    amount : 充值金额
    userId : 用户id
    token : 充值token

提取： 提取设计采用项目加密签名上传生成提取hash,此hash唯一切不可以重复，然后根据hash,由运营审核放款
    提取参数说明
    amount : 提取金额
    receiveAddress : 收款地址
    token : 提取token
    orderId : 订单号
    v : 签名v
    r : 签名r
    s : 签名s

运营管理： 运营人员的增减需要n -1个 管理人员签名通过

管理人员管理： 管理人员的增减需要n -1个 管理人员签名通过

管理员提取 ： 管理员提取需要所有管理人员签名通过

管理员提取手续费:  管理员提取手续费需要所有管理人员签名通过

 */


contract Deposit is
    IDeposit,
    IWalletManage,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20 for IERC20;

    address[] public coldWallets;
    address[] public opAddress;

    address public signer;
    uint fee ;
    mapping(address => uint) public feeMap;
    IERC20[] public suportToken;
    mapping(address => bool) public isSuportToken;

    mapping(address => uint) public isColdWallet;
    mapping(uint => IWalletManage.Wallet) public pendingWalletOp;
    mapping(bytes32 => IDeposit.WithdrawTx) public withdrawTxs;
    mapping(uint => IDeposit.AdminWithDrawTx) public depositTxs;
    CountersUpgradeable.Counter public adminWithDrawTxIndex;

    function initialize(
        address payable _coldWallet,
        address _opAddress,
        address _signer
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        _deposit_init_unchained(_coldWallet, _opAddress, _signer);
    }

    function _deposit_init_unchained(
        address payable _coldWallet,
        address _opAddress,
        address _signer
    ) internal onlyInitializing {
        coldWallets.push(_coldWallet);
        opAddress.push(_opAddress);
        signer = _signer;
        fee=3;
    }

    function changerSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function containColdWallet(address _coldWallet) internal view returns (bool) {
        for (uint i = 0; i < coldWallets.length; i++) {
            if (coldWallets[i] == _coldWallet) {
                return true;
            }
        }
        return false;
    }

    function containOpAddress(address _opAddress) internal view returns (bool) {
        for (uint i = 0; i < opAddress.length; i++) {
            if (opAddress[i] == _opAddress) {
                return true;
            }
        }
        return false;
    }

    modifier onlyWallet() {
        // require coldWallets contrain msg.sender logic
        require(containColdWallet(msg.sender), "address is not in coldwallets");
        _;
    }

    modifier onlyOpAddress() {
        // require coldWallets contrain msg.sender logic
        require(containOpAddress(msg.sender), "address is not in coldwallets");
        _;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    constructor() {}

    function deposit(
        uint amount,
        uint userId,
        IERC20 token
    ) external  override {
        require(isSuportToken[address(token)], "not suport token");
        token.transferFrom(msg.sender, address(this), amount);
        emit DepositEvent(amount, userId, token);

    }


    function addWallet(
        address _coldWallet,
        IWalletManage.Op op
    ) external override onlyWallet {
        require(isNotContainWallet(_coldWallet, op), "coldWallet is exist");
              uint signNum =2;
         if (coldWallets.length >2 ){
                signNum = coldWallets.length -1;
         }
        uint index = adminWithDrawTxIndex.current();
        pendingWalletOp[index] = IWalletManage.Wallet(
            signNum,
            _coldWallet,
            0,
            1,
            op,
            new address[](0)
        );
        adminWithDrawTxIndex.increment();
        emit AddWallet(msg.sender, _coldWallet, op, index);
    }

    function isContainWallet(
        address _coldWallet,
        IWalletManage.Op op
    ) private view returns (bool) {
        if (op == IWalletManage.Op.ColdOp) {
            return containColdWallet(_coldWallet);
        } else {
            return containOpAddress(_coldWallet);
        }
    }

    function isNotContainWallet(
        address _coldWallet,
        IWalletManage.Op op
    ) private view returns (bool) {
        if (op == IWalletManage.Op.ColdOp) {
            return !containColdWallet(_coldWallet);
        } else {
            return !containOpAddress(_coldWallet);
        }
    }

    function canWalletOp(
        address _coldWallet,
        IWalletManage.Op op,
        uint64 direct
    ) private view returns (bool) {
        if (direct == 1) {
            return isNotContainWallet(_coldWallet, op);
        } else {
            return isContainWallet(_coldWallet, op);
        }
    }

    function removeWallet(
        address _coldWallet,
        IWalletManage.Op op
    ) external override onlyWallet {
        require(isContainWallet(_coldWallet, op), "coldWallet is not exist");
        require(coldWallets.length > 1, "coldWallets length is 1");
         uint signNum =2;
         if (coldWallets.length >2 ){
                signNum = coldWallets.length -1;
         }
        uint index = adminWithDrawTxIndex.current();
        pendingWalletOp[index] = IWalletManage.Wallet(
            signNum,
            _coldWallet,
            0,
            0,
            op,
            new address[](0)
        );
        adminWithDrawTxIndex.increment();
        emit RemoveWallet(msg.sender, _coldWallet, op, index);
    }

    function signWallet(uint64 index) external {
        require(pendingWalletOp[index].status == 0, "tx is signed");
        require(containColdWallet(msg.sender), "address is not in coldwallets");
        require(
            unSigner(pendingWalletOp[index].signedAddress, msg.sender),
            "address is signed"
        );
        require(
            canWalletOp(
                pendingWalletOp[index].walletAddress,
                pendingWalletOp[index].op,
                pendingWalletOp[index].direct
            ),
            "wallet op is not allow"
        );
        pendingWalletOp[index].signedAddress.push(msg.sender);
        emit WalletSigned(msg.sender, pendingWalletOp[index].op, index);
        if (
            pendingWalletOp[index].signedAddress.length ==pendingWalletOp[index].needSignerNum
        ) {
            pendingWalletOp[index].status = 1;
            execSignOver(index);
            emit ExecSign(
                pendingWalletOp[index].walletAddress,
                pendingWalletOp[index].op,
                index,
                pendingWalletOp[index].direct
            );
        }
    }

    function execSignOver(uint index) private {
        if (pendingWalletOp[index].op == IWalletManage.Op.ColdOp) {
            if (pendingWalletOp[index].direct == 1) {
                coldWallets.push(pendingWalletOp[index].walletAddress);
            } else {
                removeElement(
                    coldWallets,
                    pendingWalletOp[index].walletAddress
                );
            }
        } else {
            if (pendingWalletOp[index].direct == 1) {
                opAddress.push(pendingWalletOp[index].walletAddress);
            } else {
                removeElement(opAddress, pendingWalletOp[index].walletAddress);
            }
        }
    }

    function removeElement(
        address[] storage array,
        address removeAddress
    ) private {
        uint length = array.length;

        uint index = 0;
        for (uint i = 0; i < length; i++) {
            if (array[i] != removeAddress) {
                array[index] = array[i];
                index++;
            }
        }
        array.pop();
    }

    function unSigner(
        address[] memory signedAddress,
        address _signer
    ) internal pure returns (bool) {
        for (uint i = 0; i < signedAddress.length; i++) {
            if (signedAddress[i] == _signer) {
                return false;
            }
        }
        return true;
    }

    function AddSuportToken(IERC20 token) external override onlyOpAddress{
        require(!isSuportToken[address(token)], "token is suport");
        suportToken.push(token);
        isSuportToken[address(token)] = true;
    }

    function getSuportToken() external view override returns (IERC20[] memory) {
        return suportToken;
    }
    

    function queryHash(
        uint amount,
        address receiveAddress,
        IERC20 token,
        string memory orderId
    ) external pure  returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    amount,
                    receiveAddress,
                    abi.encodePacked(orderId),
                    address(token)
                )
            );
    }

    function queryHashAddress(
        uint amount,
        address receiveAddress,
        IERC20 token,
        string memory orderId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure  returns (address) {

             bytes32 hashs = keccak256(abi.encodePacked(
                    amount,
                    receiveAddress,
                    abi.encodePacked(orderId),
                    address(token)
                ));
       return ecrecover(
          hashs,
            v,
            r,
            s
        );
    }

    function withdraw(
        uint amount,
        address receiveAddress,
        IERC20 token,
        string memory orderId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override  {
       bytes32 khash = keccak256(abi.encodePacked(
                    amount,
                    receiveAddress,
                    abi.encodePacked(orderId),
                    address(token)
                ));
            require( withdrawTxs[khash].status==0,"tx is exist");
        require(ecrecover(khash, v, r, s) == signer, "n2");
        require(isSuportToken[address(token)], "not suport token");
        withdrawTxs[khash] = IDeposit.WithdrawTx(
            amount,
            receiveAddress,
            address(token),
            orderId,
            1
        );

        emit CustomerWithdraw(amount, receiveAddress, token, orderId, khash);
    }

    function opAuditWithdraw(bytes32 khash) external onlyOpAddress {
        require(withdrawTxs[khash].status == 1, "tx is Audited");
        IDeposit.WithdrawTx storage withDrawTx = withdrawTxs[khash];
        withDrawTx.status = 2;
         (IERC20 (withDrawTx.token)).transfer(
            withDrawTx.receiveAddress,
            (withDrawTx.amount * (1000 - fee)) / 1000
        );
        uint feeAmount = (withDrawTx.amount * fee) / 1000;
        feeMap[address(withDrawTx.token)] += feeAmount;
        emit OpAuditWithdraw(khash, feeAmount);
    }


    function AdminWithDraw(
        uint amount,
        IERC20 token,
        address payable payAddress
    ) external onlyWallet {
        require(token.balanceOf(address(this)) >= amount, "not enough token");
        uint index = adminWithDrawTxIndex.current();
        depositTxs[index] = IDeposit.AdminWithDrawTx(
            uint64(coldWallets.length),
            1,
            amount,
            msg.sender,
            payAddress,
            IDeposit.WithDrawType.AdminWithdraw,
            token,
            new address[](0)
        );
        adminWithDrawTxIndex.increment();
        emit AdminWithdraw(amount, payAddress, token, index);
    }

    function AdminWithFee(
        uint amount,
        IERC20 token,
        address payable payAddress
    ) external onlyWallet {
        require(feeMap[address(token)] >= amount, "not enough fee");
        require(token.balanceOf(address(this)) >= amount, "not enough token");
        uint index = adminWithDrawTxIndex.current();
        depositTxs[index] = IDeposit.AdminWithDrawTx(
            uint64(coldWallets.length),
            1,
            amount,
            msg.sender,
            payAddress,
            IDeposit.WithDrawType.AdminWithdrawFee,
            token,
            new address[](0)
        );
        adminWithDrawTxIndex.increment();
        emit AdminWithdrawFee(amount, payAddress, token, index);
    }

    function signAdminWithDraw(uint index) external onlyWallet {
        require(depositTxs[index].status == 1, "tx is signed");
        require(
            unSigner(depositTxs[index].signedAddress, msg.sender),
            "address is signed"
        );
        depositTxs[index].signedAddress.push(msg.sender);
        if (
            depositTxs[index].signedAddress.length ==
            depositTxs[index].NeedSignerNum
        ) {
            depositTxs[index].status = 2;
            depositTxs[index].token.transfer(
                depositTxs[index].payAddress,
                depositTxs[index].amount
            );

            emit AdminWithDrawSucess(index);
        }
        emit Signed(msg.sender, index);
    }

    function removeColdWallets(address _coldWallet) external onlyOwner {
        require(containColdWallet(_coldWallet), "wallet is not exist");
        uint index = adminWithDrawTxIndex.current();
        pendingWalletOp[index] = IWalletManage.Wallet(
            1,
            _coldWallet,
            0,
            0,
            IWalletManage.Op.ColdOp,
            new address[](0)
        );
        adminWithDrawTxIndex.increment();
        emit RemoveWallet(msg.sender, _coldWallet, IWalletManage.Op.ColdOp, index);
    }
}
