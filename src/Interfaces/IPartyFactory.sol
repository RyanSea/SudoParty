// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ILSSVMRouter.sol";

import "../Interfaces/ISudoParty.sol";

interface IPartyFactory {

    function createPartyAny(
        string memory name,
        string memory symbol,
        address[] memory whitelist,
        uint deadline,
        uint quorum,
        address factory,
        address router,
        ILSSVMRouter.PairSwapAny[] memory pairList
    ) external returns (ISudoParty);

    function createPartySpecific(
        string memory name,
        string memory _ymbol,
        address[] memory whitelist,
        uint deadline,
        uint quorum,
        address factory,
        address router,
        ILSSVMRouter.PairSwapSpecific[] memory pairList
    ) external returns (ISudoParty);

}