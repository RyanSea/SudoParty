// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../Interfaces/ILSSVMPairFactory.sol";

import "../Interfaces/ISudoParty.sol";

import "solmate/tokens/ERC20.sol";

import "lssvm/bonding-curves/ICurve.sol";

import "openzeppelin/utils/structs/EnumerableSet.sol";

import "openzeppelin/token/ERC721/IERC721Receiver.sol";

import "Monarchy/";

/// @title SudoParty Manager
/// @author Autocrat 
/// @notice token governance for successful SudoParties
/// idea a curator role with special powers could be added
contract SudoPartyManager is ERC20, Monarchy, IERC721Receiver {

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    using EnumerableSet for EnumerableSet.UintSet;

    ILSSVMPairFactory public immutable factory;

    ISudoParty public immutable token;

    IERC721 public immutable nft;

    uint public immutable id;

    ICurve public immutable linearCurve;

    /// @notice 0 - 100% | tokens needed to complete a vote
    uint public consensus;
    
    constructor(
        string memory _name, 
        string memory _symbol,
        address party
    ) ERC20(
        string(abi.encodePacked("Staked ", _name)),
        string(abi.encodePacked("s", _symbol)),
        18
    ){
        token = ISudoParty(party);

        nft = token.nft();
        id = token.id();
        consensus = token.consensus();
        factory = token.factory();

        // rinkeby linear curve
        linearCurve = ICurve(0x3764b9FE584719C4570725A2b5A2485d418A186E);
    }

    modifier onlyStaked(address _sender) {
        require(balanceOf[_sender] > 0, "NOT_STAKED");
        _;
    }

    enum ProposalType {
        sell,
        set_consensus,
        withdraw
    }

    struct Proposal {
        ProposalType proposalType;
        bool passed;
        bool finalized;
        uint priceOrConsensus;
        uint deadline;
        uint yes;
        uint no;
        address withdrawal;
    }

    receive() external payable{}

    function onERC721Received(
        address, 
        address, 
        uint, 
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

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

    /// @notice set of active proposals
    EnumerableSet.UintSet private activeProposals;

    /*///////////////////////////////////////////////////////////////
                                STAKING
    //////////////////////////////////////////////////////////////*/ 

    /// @notice stake fractional tokens
    /// @param sender user calling SudoPartyHub function
    /// @param amount to stake
    function stake(address sender, uint amount) public ruled {
        uint memberBalance = token.balanceOf(sender);

        require(memberBalance > 0, "NO_TOKENS");

        uint _amount =  memberBalance >= amount ? amount : memberBalance;

        token.allow(amount, sender);

        token.transferFrom(sender, address(this), _amount);

        _mint(sender, _amount);
    }

    /// todo ensure sender hasn't voted on any activeProposals (offchain, maybe nested set?)
    /// @notice unstake fractional tokens
    /// @param sender user calling SudoPartyHub function
    /// @param amount to unstake
    function unstake(address sender, uint amount) public ruled onlyStaked(sender) {
        uint memberStaked = balanceOf[sender];

        uint _amount = memberStaked >= amount ? amount : memberStaked;

        _burn(sender, _amount);

        token.transfer(sender, _amount);
    }

    /// @notice claim sale of relisting
    /// @param sender user calling SudoPartyHub function
    function claim(address sender) public ruled onlyStaked(sender) {
        uint _amount = balanceOf[sender];

        _burn(sender, _amount);

        token.burn(address(this), _amount);
    }

    /*///////////////////////////////////////////////////////////////
                            PARTY GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /// @notice creates proposal
    /// @param sender user calling SudoPartyHub function
    /// @param _type proposal type
    /// @param _amount relisting price or new consensus
    function createProposal(
        address sender,
        ProposalType _type, 
        uint _amount,
        address _withdrawal
    ) public ruled onlyStaked(sender) {
        proposal_id++;

        // ensure arg <= 100 if ProposalType == set_consensus
        uint price_or_consensus = _type == ProposalType.set_consensus && _amount > 100 ? 100 : _amount;

        activeProposals.add(proposal_id);

        Proposal memory _proposal;

        _proposal.proposalType = _type;
        _proposal.priceOrConsensus = price_or_consensus;
        _proposal.deadline = block.timestamp + 1 days;
        _proposal.withdrawal = _withdrawal;

        proposal[proposal_id] = _proposal;
    }

    /// @notice cast vote
    /// @param sender user calling SudoPartyHub function
    /// @param _id proposal id
    /// @param _vote yes/no vote
    function vote(
        address sender, 
        uint _id, 
        bool _vote
    ) public ruled onlyStaked(sender) {
        Proposal memory _proposal = proposal[_id];

        address member = msg.sender;

        require(!voted[member][_id], "ALREADY_VOTED");

        require(activeProposals.contains(_id) && block.timestamp < _proposal.deadline, "PROPOSAL_INACTIVE");

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
    function finalize(uint _id) public {
        require(activeProposals.contains(_id), "ALREADY_FINALIZED");

        activeProposals.remove(_id);

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

    /// @param sender user calling SudoPartyHub function
    /// @param _address withdrawal address
    /// @notice withdraws to staked / unstaked sole-owner
    /// todo ensure non-rentry
    function withdraw(address sender, address _address) public ruled {
        uint _tokens = token.balanceOf(sender);

        uint _stake = balanceOf[sender];

        assert(_stake + _tokens == token.totalSupply());

        if (_tokens > 0) token.burn(sender, _tokens);

        if (_stake > 0) {
            _burn(sender, _stake);

            token.burn(address(this), token.balanceOf(address(this)));
        }

        nft.transferFrom(address(this), _address, id);
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

        // set & init ids array
        uint[] memory _ids = new uint[](1);
        _ids[0] = id;

        nft.approve(address(factory), id);

        listing = address(factory.createPairETH(
            nft,
            linearCurve,
            payable(address(this)),
            ILSSVMPair.PoolType.NFT,
            .01 ether,
            0,
            _price,
            _ids
        ));
    }

    /// @notice changes consensus
    function handleNewConsensus(Proposal memory _proposal) private {
        consensus = _proposal.priceOrConsensus;
    }

    /// @notice withdraws to proposal's withdrawal address
    function handleWithdraw(address _withdrawal) private {
        nft.transferFrom(address(this), _withdrawal, id);
    }

    /*///////////////////////////////////////////////////////////////
                                SOULBOUND                                                   
    //////////////////////////////////////////////////////////////*/

    function transfer(address, uint) public virtual override returns (bool) {
        revert("SOULBOUND");
    }

    function transferFrom(address, address, uint) public virtual override returns (bool) {
        revert("SOULBOUND");
    }
}