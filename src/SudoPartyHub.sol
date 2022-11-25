// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ILSSVMRouter.sol";

import "./interfaces/ISudoParty.sol";
import "./interfaces/ISudoPartyManager.sol";

import "./interfaces/IPartyFactory.sol";
import "./interfaces/IManagerFactory.sol";

import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/utils/Strings.sol";

/// @title SudoParty Hub
/// @author Autocrat
/// @notice creates & routes SudoParties
contract SudoPartyHub {

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/ 

    /// @notice SudoPartyAny Factory
    IPartyFactory public immutable factory_any;

    /// @notice SudoPartySpecific Factory
    IPartyFactory public immutable factory_specific;

    /// @notice SudoParty Manager Factory
    IManagerFactory public immutable manager_factory;

    constructor(
        address _factory_any, 
        address _factory_specfic,
        address _manager_factory
    ) {
        factory_any = IPartyFactory(_factory_any);
        factory_specific = IPartyFactory(_factory_specifc);
        manager_factory = IManagerFactory(_manager_factory);
    }

    /// @notice SudoParty => SudoParty's Manager
    mapping (ISudoParty => ISudoPartyManager) public manager;

    /*///////////////////////////////////////////////////////////////
                            SUDOPARTY CREATION
    //////////////////////////////////////////////////////////////*/ 

    /// @notice creates SudoParty buying any nft id's
    function startPartyAny(
        string calldata name,
        string calldata symbol,
        address[] memory whitelist,
        uint deadline,
        uint quorum,
        address factory,
        address router,
        ILSSVMRouter.PairSwapAny[] memory pairList

    ) public returns (ISudoParty party) {
        // create party
        ISudoParty party = factory_any.createPartyAny(
            name, 
            symbol, 
            whitelist, 
            deadline, 
            quorum, 
            factory, 
            router, 
            pairList
        );

        // create manager
        address _manager = manager_factory.createManager(name, symbol, party);

        // map manager to party
        manager[party] = _manager;

        // set manager to party
        party.setManager(_manager);
    }
    
    /// @notice creates SudoParty buying specific nft id's
    function startPartySpecific(
        string calldata name,
        string calldata symbol,
        address[] memory whitelist,
        uint deadline,
        uint quorum,
        address factory,
        address router,
        ILSSVMRouter.PairSwapSpecific[] memory pairList
    ) public returns (ISudoParty party) {
        // create party
        party = factory_specific.createPartySpecific(
            name, 
            symbol, 
            whitelist, 
            deadline, 
            quorum, 
            factory, 
            router, 
            pairList
        );

        // create manager
        address _manager = manager_factory.createManager(name, symbol, party);

        // map manager to party
        manager[party] = _manager;

        // set manager to party
        party.setManager(_manager);
    }

    /*///////////////////////////////////////////////////////////////
                              SUDOPARTY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function whitelistAdd(address party, address new_contributor) public {
        address sender = msg.sender; 

        ISudoParty(party).whitelistAdd(sender, new_contributor);
    }

    function openParty(address party) public {
        address sender = msg.sender;

        ISudoParty(party).openParty(sender);
    }

    function contribute(address party) public payable {
        address sender = msg.sender; 

        ISudoParty(party).contribute{value: msg.value}(sender);
    }

    function buy(address party) public {
        ISudoParty(party).buy();
    }

    function finalize(address party) public {
        ISudoParty(party).finalize();
    }

    function claim(address party, address contributor) public {
        ISudoParty(party).claim(contributor);
    }

    /*///////////////////////////////////////////////////////////////
                            SUDOPARTY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function stake(address party, uint amount) public {
        address sender = msg.sender;

        manager[ISudoParty(party)].stake(sender, amount);
    }

    function unstake(address party, uint amount) public {
        address sender = msg.sender;

        manager[ISudoParty(party)].unstake(sender, amount);
    }

    function claimSale(address party) public {
        address sender = msg.sender;

        manager[ISudoParty(party)].claim(sender);
    }

    function createProposal(
        address party, 
        ISudoPartyManager.ProposalType _type, 
        uint amount,
        address withdrawal
    ) public {
        address sender = msg.sender;

        manager[ISudoParty(party)].createProposal(sender, _type, amount, withdrawal);
    }

    function vote(
        address party,
        uint id,
        bool yes
    ) public {
        address sender = msg.sender;

        manager[ISudoParty(party)].vote(sender, id, yes);
    }

    function finalizeProposal(address party, uint id) public {
        manager[ISudoParty(party)].finalize(id);
    }

    function withdraw(address party, address withdrawal) public {
        address sender = msg.sender;

        manager[ISudoParty(party)].withdraw(sender, withdrawal);
    }
}