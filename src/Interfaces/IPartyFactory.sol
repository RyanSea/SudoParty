// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ILSSVMRouter.sol";

interface IPartyFactory {

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
    ) external returns (address payable);

    function createPartySpecific(
        string memory _name,
        string memory _symbol,
        address[] memory whitelist,
        uint _deadline,
        uint _quorum,
        address _factory,
        address _router,
        ILSSVMRouter.PairSwapSpecific[] memory _pairList
    ) external returns (address payable);

}