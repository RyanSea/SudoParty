// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../SudoParty/SudoPartyManager.sol";

/// @notice factory for SudoParty Manager
contract ManagerFactory {
    function createManager(
        string memory name, 
        string memory symbol,
        address party
    ) public returns (address) {
        SudoPartyManager manager = new SudoPartyManager(name, symbol, party);

        return address(manager);
    }
}