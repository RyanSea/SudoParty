// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../SudoParty/SudoPartySpecific.sol";

import "../Interfaces/ISudoParty.sol";

contract PairFactorySpecific {
    function createPartySpecific(
        string memory _name,
        string memory _symbol,
        address[] memory whitelist,
        uint _deadline,
        uint _quorum,
        address _factory,
        address _router,
        ILSSVMRouter.PairSwapSpecific[] memory _pairList
    ) public returns (ISudoParty) {
        SudoPartySpecific party = new SudoPartySpecific(
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

        return ISudoParty(party);
    }
}