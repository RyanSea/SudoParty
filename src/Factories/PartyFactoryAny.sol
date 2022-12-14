// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../sudoparty/SudoPartyAny.sol";

import "../interfaces/ISudoParty.sol";

/// @notice factory for SudoParties
contract PartyFactoryAny {
   function createPartyAny(
        string memory name,
        string memory _name,
        string memory _symbol,
        address[] memory whitelist,
        uint _deadline,
        uint _quorum,
        address _factory,
        address _router,
        ILSSVMRouter.PairSwapAny[] memory _pairList
    ) public returns (ISudoParty) {
        SudoParty party = new SudoPartyAny(
            _name,
            _symbol,
            whitelist,
            _deadline,
            _quorum,
            _factory,
            _router,
            _pairList
        );

        party.annoint(msg.sender);

        return ISudoParty(address(party));
    }
}