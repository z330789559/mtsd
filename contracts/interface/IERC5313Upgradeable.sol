// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5313.sol)

pragma solidity ^0.8.9;

/**
 * @dev Interface for the Light Contract Ownership Standard.
 *
 * A standardized minimal interface required to identify an account that controls a contract
 *
 * _Available since v4.9._
 */
interface IERC5313Upgradeable {
    /**
     * @dev Gets the address of the owner.
     */
    function owner() external view returns (address);
}