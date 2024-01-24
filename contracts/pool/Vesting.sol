// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


library Vesting {
  struct Pool {
        uint256 firstUnlockAmount;
        uint256 startBlock;
        uint256 cliff;
        uint256 vestingAmount;
        uint256 released;
        address[] beneficiaries;
    }

   function initVestingPool() internal  view returns (Pool memory){

   }
   
  


}