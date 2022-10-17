// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ISudoParty.sol";

interface IManagerFactory {

    function createManager(
        string memory name, 
        string memory symbol,
        ISudoParty party
    ) external returns (address);
    
}