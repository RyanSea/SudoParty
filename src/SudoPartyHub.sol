// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./SudoParty.sol";
import "./SudoPartyManager.sol";

import "./Interfaces/ILSSVMPairFactory.sol";
import "./Interfaces/ILSSVMRouter.sol";
import "./Interfaces/ILSSVMPair.sol";

import "openzeppelin/token/ERC721/IERC721.sol";

                                /// @notice UNUSED EXAMPLE  ///


/// @notice router for SudoParties
contract SudoPartyHub {

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/ 

    /// @notice bytes(pool,nft,id) => SudoParty
    mapping (bytes => SudoParty) public party;

    /// @notice SudoParty => SudoParty's Manager
    mapping (SudoParty => SudoPartyManager) public manager;

    function startParty(
        address[] memory whitelist,
        uint consensus,
        uint deadline,
        address router,
        address factory,
        address pool, 
        address nft, 
        uint id
    ) public {
        // create party
        SudoParty _party = new SudoParty(
            whitelist,
            consensus,
            deadline,
            ILSSVMRouter(router),
            ILSSVMPairFactory(factory),
            LSSVMPair(pool),
            IERC721(nft),
            id
        );

        // assign party to mapping based on pool, nft, id casted into bytes
        party[bytes(abi.encodePacked(pool,nft,id))] = _party;
    }

    function partyGetter(
        address pool, 
        address nft, 
        address id
    ) private pure returns (bytes memory) {
        return bytes(abi.encodePacked(pool,nft,id));
    }

    /*///////////////////////////////////////////////////////////////
                            SUDOPARTY INTERFACE
    //////////////////////////////////////////////////////////////*/

                //======== SudoParty Functions ========//

    function contribute(address pool, address nft, address id) public payable {
        /* address sender = msg.sender; */

        party[partyGetter(pool, nft, id)].contribute{value: msg.value}(/* sender */);
    }

    function buy(address pool, address nft, address id) public payable {
        party[partyGetter(pool, nft, id)].buy();
    }

    function finalize(address pool, address nft, address id) public {
        party[partyGetter(pool, nft, id)].finalize();
    }




    

}