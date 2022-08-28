// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Interfaces/ILSSVMPairFactory.sol";

import "solmate/tokens/ERC20.sol";

import "lssvm/bonding-curves/ICurve.sol";

import "lssvm/LSSVMPairETH.sol";

//import "./SudoParty.sol";

import "forge-std/console.sol";

import "./Interfaces/ISudoParty.sol";

/// @title SudoParty Manager
/// @author Autocrat (Ryan)
/// @notice token governance for successful SudoParties
/// idea a curator role with special powers could be added
contract SudoPartyManager is ERC20 {

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    ILSSVMPairFactory public immutable factory;

    ISudoParty public immutable token;

    IERC721 public immutable nft;

    uint public immutable id;

    ICurve public immutable linearCurve;

    /// @notice 0 - 100% | tokens needed to complete a vote
    uint public consensus;
    
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
        factory = token.factory();

        // rinkeby linear curve
        linearCurve = ICurve(0x3764b9FE584719C4570725A2b5A2485d418A186E);
    }

    modifier onlyStaked {
        require(balanceOf[msg.sender] > 0, "NOT_STAKED");
        _;
    }

    enum ProposalType {
        sell,
        set_consensus,
        withdraw
    }

    struct Proposal {
        ProposalType proposalType;
        uint priceOrConsensus;
        uint deadline;
        bool passed;
        uint yes;
        uint no;
        address withdrawal;
    }

    receive() external payable{}

    /*///////////////////////////////////////////////////////////////
                            MANAGER VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice proposal id
    uint proposal_id;

    /// @notice re-listing address
    address public listing;

    /// @notice proposal id => if it's finalized
    mapping (uint => bool) public finalized;

    // proposal id => proposal struct
    mapping (uint => Proposal) public proposal;

    /// @notice address => proposal id => if they voted
    mapping (address => mapping(uint => bool)) public voted;

    /*///////////////////////////////////////////////////////////////
                                STAKING
    //////////////////////////////////////////////////////////////*/ 

    /// @notice stake fractional tokens
    /// @param amount to stake
    function stake(uint amount) public {
        address member = msg.sender;

        uint memberBalance = token.balanceOf(msg.sender);

        require(memberBalance > 0, "NO_TOKENS");

        uint _amount =  memberBalance >= amount ? amount : memberBalance;

        token.transferFrom(msg.sender, address(this), _amount);

        _mint(member, _amount);
    }

    /// @notice unstake fractional tokens
    /// @param amount to unstake
    function unstake(uint amount) public onlyStaked {
        address member = msg.sender;

        uint memberStaked = balanceOf[member];

        uint _amount = memberStaked >= amount ? amount : memberStaked;

        _burn(member, _amount);

        token.transfer(member, _amount);
    }

    /// @notice claim sale of relisting
    function claim(uint amount) public onlyStaked {
        uint _amount = amount > balanceOf[msg.sender] ? balanceOf[msg.sender] : amount;

        _burn(msg.sender, _amount);

        token.claimSale(_amount);
    }

    /*///////////////////////////////////////////////////////////////
                            PARTY GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /// @notice creates proposal
    /// @param _type proposal type
    /// @param _amount relisting price or new consensus
    function createProposal(ProposalType _type, uint _amount) public onlyStaked {
        proposal_id++;

        // ensure arg <= 100 if ProposalType == set_consensus
        uint price_or_consensus = _type == ProposalType.set_consensus && _amount > 100 ? 100 : _amount;

        Proposal memory _proposal;

        _proposal.proposalType = _type;
        _proposal.priceOrConsensus = price_or_consensus;
        _proposal.deadline = block.timestamp + 1 days;

        proposal[proposal_id] = _proposal;
    }

    /// @notice cast vote
    /// @param _id proposal id
    /// @param _vote yes/no vote
    function vote(uint _id, bool _vote) public onlyStaked {
        Proposal memory _proposal = proposal[_id];

        address member = msg.sender;

        require(!voted[member][_id], "ALREADY_VOTED");

        require(block.timestamp < _proposal.deadline, "DEADLINE_PASSED");

        voted[member][id] = true;

        uint value = balanceOf[member];

        if (_vote) {
            _proposal.yes += value;
        } else if (!_vote) {
            _proposal.no += value;
        }

        proposal[_id] = _proposal;
    }

    /// @notice finalize proposal
    /// @param _id proposal id
    function finalize(uint _id) public onlyStaked {
        require(!finalized[_id], "ALREADY_FINALIZED");

        Proposal memory _proposal = proposal[_id];

        uint yes = _proposal.yes;

        uint no = _proposal.no;

        uint _consensus = token.totalSupply() * consensus;

        if (_proposal.passed = yes >= no) {
            // multiply yes votes by same multipler to get consensus to whole number
            require(yes * 100 >= _consensus, "CONSENSUS_UNMET");

            finalized[_id] = true;

            _proposal.passed = true;

            handleProposal(_proposal);

        } else if (_proposal.deadline >= block.timestamp) {
            finalized[_id] = true;

            _proposal.passed = false;
        }

        proposal[_id] = _proposal;
    }

    /*///////////////////////////////////////////////////////////////
                            SOLE-OWNER WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @notice withdraws to staked / unstaked sole-owner
    /// todo ensure non-rentry
    /// note just a PoC
    function withdraw(address _address) public {
        uint _tokens = token.balanceOf(msg.sender);

        uint _stake = balanceOf[msg.sender];

        assert(_stake + _tokens == token.totalSupply());

        token.withdraw(_address);
    }
    /*///////////////////////////////////////////////////////////////
                            PROPOSAL HANDLERS
    //////////////////////////////////////////////////////////////*/

    /// @notice routes proposal to handler based on proposal type
    function handleProposal(Proposal memory _proposal) private {
        ProposalType _type = _proposal.proposalType;

        if (_type == ProposalType.sell) {
           handleRelist(_proposal);
        } else if (_type == ProposalType.set_consensus) {
            handleNewConsensus(_proposal);

        } else if(_type == ProposalType.withdraw) {
            address _withdrawal;

            handleWithdraw(_withdrawal);
        }
    }

    /// @notice relists nft on sudoswap & sets listing address
    function handleRelist(Proposal memory _proposal) private {
        uint128 _price = uint128(_proposal.priceOrConsensus);
        
        // fee = 0.5% (unused)
        //uint96 _fee = uint96(_price * 5 / 100);

        // set & init ids array
        uint[] memory _ids = new uint[](1);
        _ids[0] = id;

        nft.approve(address(factory), id);

        LSSVMPairETH pair = factory.createPairETH(
            nft,
            linearCurve,
            payable(address(this)),
            LSSVMPair.PoolType.NFT,
            .01 ether,
            0,
            _price,
            _ids
        );

        listing = address(pair);
    }

    /// @notice changes consensus
    function handleNewConsensus(Proposal memory _proposal) private {
        consensus = _proposal.priceOrConsensus;
    }

    /// @notice withdraws to proposal's withdrawal address
    function handleWithdraw(address _withdrawal) private {
        nft.transferFrom(address(this), _withdrawal, id);
    }

}