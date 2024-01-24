// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5313.sol)

pragma solidity ^0.8.9;

/**
* 释放池合约
* 1. 释放池合约，用于释放用户的代币
 */
interface IPool{

    /**
    * @dev 获取释放池合约的所有者
    */
    function owner() external view returns (address);

    /**
    * @dev 获取池合约的代币
    */
    function token() external view returns (address);

    /**
    * @dev 获取释放合约未释放的时间
    */ 
    function releaseTime() external view returns (uint256);

    /**
    * @dev 未释放的金额
    */
    function releaseAmount() external view returns (uint256);

    /**
    * @dev 已经释放的金额
    */
    function releasedAmount() external view returns (uint256);

    /**
    * @dev 已经释放的时间
    */
    function releasedTime() external view returns (uint256);



}