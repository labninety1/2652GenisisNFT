// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Interface of IFoldStaking.
 */
interface IFoldStaking {
    function deposit(uint _amount,address _to) external;
    function withdraw(uint _amount,address _from) external;
    function isValidLP(address _lpAddress) external returns (bool isValid);
}