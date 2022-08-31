// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPartyFactory {

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
    ) external returns (address);

}