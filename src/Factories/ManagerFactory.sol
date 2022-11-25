// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../sudoparty/SudoPartyManager.sol";

/// @notice factory for SudoParty Manager
contract ManagerFactory {
    function createManager(
        string memory name, 
        string memory symbol,
        ISudoParty party
    ) public returns (address) {
        SudoPartyManager manager = new SudoPartyManager(name, symbol, party);

        manager.annoint(msg.sender);

        return address(manager);
    }
}