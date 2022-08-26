// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lssvm/ILSSVMPairFactoryLike.sol";

import "solmate/tokens/ERC20.sol";

//import "./SudoParty.sol";

import "./Interfaces/ISudoParty.sol";

/// @title SudoParty Manager
/// @author Autocrat (Ryan)
/// @notice token governance for successful SudoParties
/// idea a curator role with special powers may be called for
contract SudoPartyManager is ERC20 {

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/ 

    //ILSSVMRouter public immutable router;

    ISudoParty public immutable token;

    IERC721 public immutable nft;

    uint public immutable id;

    /// @notice 0 - 100% | tokens needed to complete a vote
    uint public immutable consensus;
    
    constructor(string memory _name, string memory _symbol) 
    ERC20(
        string(abi.encodePacked("Staked ", _name)),
        string(abi.encodePacked("s", _symbol)),
        18
    ){
        token = ISudoParty(msg.sender);

        nft = token.nft();
        id = token.id();
        consensus = token.consensus();
    }

    modifier onlyStaked {
        require(balanceOf[msg.sender] > 0, "NOT_STAKED");
        _;
    }

    enum ProposalType {
        eth,
        set_consensus,
        withdraw
    }

    enum PairVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    struct Proposal {
        ProposalType proposalType;
        uint priceOrConsensus;
        uint deadline;
        bool passed;
        uint yes;
        uint no;
    }

    /*///////////////////////////////////////////////////////////////
                            MANAGER VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice proposal id
    uint proposal_id;

    mapping (uint => bool) public finalized;

    mapping (uint => Proposal) public proposal;

    /// @notice user => proposal id => if they voted
    mapping (address => mapping(uint => bool)) public voted;

    /*///////////////////////////////////////////////////////////////
                                STAKING
    //////////////////////////////////////////////////////////////*/ 

    function stake(uint amount) public {
        address member = msg.sender;

        uint memberBalance = token.balanceOf(msg.sender);

        require(memberBalance > 0, "NO_TOKENS");

        uint _amount =  memberBalance >= amount ? amount : memberBalance;

        transferFrom(msg.sender, address(this), _amount);

        _mint(member, _amount);
    }

    function unstake(uint amount) public onlyStaked {
        address member = msg.sender;

        uint memberStaked = balanceOf[member];

        uint _amount = memberStaked >= amount ? amount : memberStaked;

        _burn(member, _amount);

        token.transfer(member, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                            PARTY GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    function createProposal(ProposalType _type, uint _amount) public onlyStaked {
        // ensure arg <= 100 if ProposalType == set_consensus
        uint price_or_consensus = _type == ProposalType.set_consensus && _amount > 100 ? 100 : _amount;

        _proposal.proposalType = _type;
        _proposal.priceOrConsensus = price_or_consensus;
        _proposal.deadline = block.timestamp + 1 days;

        proposal[id] = _proposal;
    }

    function vote(uint _id, bool _vote) public onlyStaked {
        Proposal memory _proposal = proposal[_id];

        address memeber = msg.sender;

        require(!voted[member][_id], "ALREADY_VOTED");

        require(block.timestamp > _proposal.deadline, "DEADLINE_PASSED");

        voted[member][id] = true;

        uint value = balanceOf[member];

        if (_vote) {
            _proposal.yes += value;
        } else if (!_vote) {
            _proposal.no += value;
        }

        proposal[_id] = _proposal;
    }

    function finalize(uint _id) public onlyStaked {
        require(!finalized[_id], "ALREADY_FINALIZED");

        Proposal memory _proposal = proposal[_id];

        uint yes = _proposal.yes;

        uint no = _proposal.no;

        uint _consensus = token.totalSuppy() * consensus / 100;

        if (_proposal.passed = yes >= no) {
            require(yes >= _conensus, "CONSENSUS_UNMET");

            finalized[_id] = true;


        } else if (_proposal.deadline >= block.timestamp) {
            finalized[_id] = true;
        }

        

        require(yes + no >= _consensus, "CONSENSUS_UNMET");

        finalized[_id] = true;

        bool _passed = yes > 

    }

    function handleProposal(uint _id) private {

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