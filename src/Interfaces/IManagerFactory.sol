// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IManagerFactory {

    function createManager(
        string memory name, 
        string memory symbol,
        address party
    ) external returns (address);
    
}