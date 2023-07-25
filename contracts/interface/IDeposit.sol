// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";

interface IDeposit {
    enum WithDrawType {
        CustomerWithdraw,
        OpAduitWithdraw,
        AdminWithdraw,
        AdminWithdrawFee
    }

    struct AdminWithDrawTx {
        uint64 NeedSignerNum;
        uint64 status;
        uint256 amount;
        address sender;
        address payable payAddress;
        WithDrawType withDrawType;
        IERC20 token;
        address[] signedAddress;
    }
    //uint amount, address receiveAddress, IERC20 token, string orderId
    struct WithdrawTx {
        uint amount;
        address receiveAddress;
        address token;
        string orderId;
        uint status;
    }

    event DepositEvent(uint amount, uint userId, IERC20 token);
    event Withdraw(uint amount, address payAddress, IERC20 token, uint userId);
    event CustomerWithdraw(
        uint amount,
        address payAddress,
        IERC20 token,
        string orderId,
        bytes32 khash
    );
    event Fee(address token, uint amount, uint index);
    event OpAduitWithdraw(bytes32 index, uint amount);
    event AdminWithdraw(
        uint amount,
        address payAddress,
        IERC20 token,
        uint index
    );
    event AdminWithdrawFee(
        uint amount,
        address payAddress,
        IERC20 token,
        uint index
    );
    event Signed(address signer, uint index);
    event AdminWithDrawSucess(uint index);

    function deposit(uint amount, uint userId, IERC20 token) external ;

    function AddSuportToken(IERC20 token) external;

    function getSuportToken() external view returns (IERC20[] memory);

    function withdraw(
        uint amount,
        address receiveAddress,
        IERC20 token,
        string memory orderId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
