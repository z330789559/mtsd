// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IWalletManage{

    struct Wallet{
        uint256 needSignerNum;
        address walletAddress;
        uint64 status;
        uint64  direct;
        Op op;
        address[] signedAddress;
    }
    enum Op{
         ColdOp,
         HotOp
    }



    function addWallet(address walletAddress,Op op ) external;

    function removeWallet(address walletAddress, Op op) external;

    event AddWallet(address sender,address walletAddress,Op op, uint index);

    event RemoveWallet(address sender,address walletAddress,Op op, uint index);

    event WalletSigned(address signer,Op op, uint64 index);

    event ExecSign(address walletAddress,Op op, uint64 index,uint64 direct);

}