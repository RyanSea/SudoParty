// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lssvm/ILSSVMPairFactoryLike.sol";

import "solmate/tokens/ERC20.sol";

import "./SudoParty.sol";

/// @title SudoParty Manager
/// @author Autocrat (Ryan)
/// @notice Token Governance for SudoParties 
contract SudoPartyManager {

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/ 

    ILSSVMRouter public immutable router;

    IERC721 public immutable nft;

    uint public immutable id;

    ERC20 public immutable token;

    constructor(
        
    ){

    }

    // mapping (bytes => address) party;

    // function startParty(
    //     address pool, 
    //     address nft, 
    //     uint id
    // ) public {
    //     _party = new SudoParty(pool, nft, id);

    //     party[bytes(abi.encodePacked(pool,nft,id))] = _party;
    // }



    

}