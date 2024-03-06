// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

/*
* @title EnefteOwnership
* @author lileddie.eth / Enefte Studio
*/

contract EnefteOwnership {
    
    address _owner;
    
    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        setOwner(newOwner);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) internal {
        //require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}