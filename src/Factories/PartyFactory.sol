// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../SudoParty/SudoParty.sol";

/// @notice factory for SudoParties
contract PartyFactory {
   function createParty(
        string memory name,
        string memory symbol,
        address[] memory whitelist,
        uint deadline,
        uint consensus,
        address factory,
        address router,
        address pool, 
        address nft, 
        uint id
    ) public returns (address) {
        SudoParty party = new SudoParty(
            name,
            symbol,
            whitelist,
            deadline,
            consensus,
            factory,
            router,
            pool,
            nft,
            id
        );

        return address(party);
    }
}