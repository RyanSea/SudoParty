// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lssvm/LSSVMPair.sol";

import "./Interfaces/ILSSVMRouter.sol";

/// @dev added name() and symbol() to IERC721.sol
import "openzeppelin/token/ERC721/IERC721.sol";

import "openzeppelin/utils/Strings.sol";

import "solmate/tokens/ERC20.sol";

import "./SudoPartyManager.sol";

/// @title SudoParty!
/// @author Autocrat (Ryan)
/// @notice buys and fractionalizes nft's from Sudoswap
/// @author modified from PartyBid
contract SudoParty is ERC20 {

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/ 

    /// @notice address => if its on whitelist
    mapping (address => bool) whitelisted;

    /// @notice Sudoswap router address
    ILSSVMRouter public immutable router;

    /// @notice 0 - 100 (%)| consensus needed to pass a yes vote
    uint public immutable consensus;
    
    /// @notice deadline for SudoParty to complete purchase
    uint public immutable deadline;

    /// @notice Sudoswap pool to buy from
    LSSVMPair public immutable pool;

    /// @notice target nft
    IERC721 public immutable nft;

    /// @notice target nft id
    uint public immutable id;

    /// @notice whether or not this party is open to all
    bool public open;

    constructor(
        address[] memory whitelist,
        uint _consensus,
        uint _deadline,
        address _router,
        address _pool, 
        address _nft, 
        uint _id
    ) ERC20(
        // e.g. CRYPTOPUNKS#6529 Fraction
        string(abi.encodePacked(IERC721(_nft).name(), "#",Strings.toString(_id), " Fraction")),
        // e.g. Ͼ#6529
        string(abi.encode(IERC721(_nft).symbol(), "#",Strings.toString(_id))),
        18
    ) {
        consensus = _consensus >= 100 ? 100 : _consensus;
        router = ILSSVMRouter(_router);
        pool = LSSVMPair(_pool);
        nft = IERC721(_nft);
        deadline = _deadline;
        id = _id;

        setWhitelist(whitelist);

        status = Status.active;
    }

    address public constant rinkeby_pairfactory = 0x9ABDe410D7BA62fA11EF37984c0Faf2782FE39B5;

    enum Status { 
        active, 
        closed,
        finalized
    }

    struct Contribution {
        uint amount;
        uint totalContributions;
    }

    /*///////////////////////////////////////////////////////////////
                            PARTY VARIABLES
    //////////////////////////////////////////////////////////////*/ 

    /// @notice nft price
    uint public price;

    /// @notice eth spent
    uint public spent;

    /// @notice total contributions to party
    uint public partybank;

    /// @notice current status of party
    Status public status;

    /// @notice SudoParty Manager
    SudoPartyManager public manager;

    /// @notice contributor => whether or not they claimed
    mapping(address => bool) public claimed;

    /// @notice user contributions counter
    mapping (address => uint) public totalUserContribution;

    /// @notice user contributions holder
    mapping (address => Contribution[]) public contributions;

    /*///////////////////////////////////////////////////////////////
                                PARTY EVENTS
    //////////////////////////////////////////////////////////////*/ 

    event NewContribution(
        address indexed contributor, 
        uint amount, 
        uint all_user_contributions,
        uint all_party_contributions
    );

    event Claimed(
        address indexed contribtutor,
        uint contributionSpent,
        uint contributionUnspent
    );

    event Finalized(bool successful);

    event PartyWon(uint cost, uint unspent);

    /*///////////////////////////////////////////////////////////////
                            SUDOPARTY FUNCTIONS
    //////////////////////////////////////////////////////////////*/ 

    /// @notice adds msg.sender's contribution
    function contribute() public payable {
        require(status == Status.active, "PARTY_CLOSED");

        require(open ? true : whitelisted[msg.sender], "NOT_MEMBER");

        uint amount = msg.value;

        // ensure total contribution isn't higher than nft price + arbitrary amount
        require(amount + partybank <= getPrice() + 2 ether, "CONTRIBUTION_TOO_HIGH");
        
        require(amount > 0, "CONTRIBUTION_TOO_LOW");

        // create contribution struct 
        Contribution memory contribution = Contribution(amount, partybank);

        // push to user contributions holder
        contributions[msg.sender].push(contribution);

        // add amount to user contributions counter 
        totalUserContribution[msg.sender] += amount;

        // add amount to total contributed to party
        partybank += amount;

        emit NewContribution(msg.sender, amount, totalUserContribution[msg.sender], partybank);
    }

    /// @notice attempts to buy nft 
    /// @notice sudoswap returns unused eth to contract
    /// @dev may need re-entrancy guard for buying non-specific nft's
    /// note might a _deadline param for Sudoswap's deadline arg
    function buy() public payable {
        require(status == Status.active, "PARTY_CLOSED");

        // initialize PairSwapSpecifc
        ILSSVMRouter.PairSwapSpecific memory swap;

        swap.pair = LSSVMPair(pool);
        swap.nftIds = new uint[](1);
        swap.nftIds[0] = id;

        // initialize PairSwapSpecifc[] which is a param for buying nft's by id
        ILSSVMRouter.PairSwapSpecific[] memory pairList = new ILSSVMRouter.PairSwapSpecific[](1);

        pairList[0] = swap;

        // update price
        getPrice();

        // assert to keep the price update to state
        assert(partybank >= price);

        // attempt to buy
        uint unspent = router.swapETHForSpecificNFTs {value: price} (
            pairList, 
            payable(address(this)), 
            address(this), 
            block.timestamp + 240 // swap deadline
        );

        spent = price;

        status = Status.closed;

        emit PartyWon(spent, unspent);
    }

    /// @notice mints tokens & creates SudoPartyManager if purchase succeeded
    /// @notice finalizes party if purchase succeeded or deadline passed
    function finalize() public {
        bool complete = nft.ownerOf(id) == address(this);

        if (complete) {
            status = Status.finalized;

            _mint(address(this), spent);

            manager = new SudoPartyManager(name, symbol);

        } else if (block.timestamp >= deadline) {
            status = Status.finalized;
        }

        if(status == Status.finalized) emit Finalized(complete);
    }

    /// @notice returns user's claimable assets if party is finaized
    /// TODO ensure non re-entry
    function claim(address contributor) public {
        require(status == Status.finalized, "NOT_FINALIZED");

        require(totalUserContribution[contributor] > 0, "NO_CONTRIBUTION");

        require(!claimed[contributor], "ALREADY_CLAIMED");

        claimed[contributor] = true;

        // _spent = tokens to give, _unspent = eth to return
        (uint tokens, uint eth) = ethSpent(contributor);

        if (eth > 0) payable(contributor).transfer(eth);

        if (tokens > 0) transfer(contributor, tokens);

        emit Claimed(contributor, tokens, eth);
    }

    /*///////////////////////////////////////////////////////////////
                            CONTRIBUTOR ACCOUNTING                                                   
    //////////////////////////////////////////////////////////////*/

    /// @notice returns the amount of eth that was spent & unspent from a contributor
    /// @notice total eth spent from contributor on purchase / their claimable amount of tokens
    /// @notice total unspent from contributor / their claimable amount of eth
    /// @dev this does in one function what PartyBid does in 2 
    function ethSpent(address contrbutor) public view returns (uint _spent, uint _unspent) {
        
        // memory holder for total spent on nft
        uint totalSpent = spent;

        // memory holder for total user contribtions
        uint totalContributions = contributions[contrbutor].length;

        // holder of a single user contribition amount
        uint _amount;

        // memory holder for a single user contribution struct
        Contribution memory contribution;

        if (totalSpent > 0) {

            // iterates through contributions of a user
            for(uint i; i < totalContributions; i++) {
                contribution = contributions[contrbutor][i];

                // this uses a ternary where PartyBid's Party.sol uses if statements, otherwise the same
                _amount = contribution.amount + contribution.totalContributions <= totalSpent ?
                    contribution.amount : contribution.totalContributions < totalSpent ?
                        totalSpent - contribution.totalContributions : 0;
                
                // if 0 eth was contributed, any subsequent contributions are meaningless
                if (_amount == 0) break;

                _spent += _amount;
            }

                // guard against rounding errors h/t PartyBid
                _spent = _spent <= totalSupply ? _spent : totalSupply;
        }

        // if 0 is spent on nft then _spent is 0
        _unspent = totalContributions - _spent;
    }

    /*///////////////////////////////////////////////////////////////
                                SUDO QUERY                                                    
    //////////////////////////////////////////////////////////////*/

    /// @notice return true if pool holds nft id
    function isListed() public view returns (bool listed) {
        listed = nft.ownerOf(id) == address(pool);
    }

    /// @notice sets price to current spot price and returns price
    function getPrice() public returns (uint) {
        require(isListed(), "NOT_LISTED");

        (, uint newSpotPrice,,,) = pool.getBuyNFTQuote(1);

        return price = newSpotPrice;
    }

    /*///////////////////////////////////////////////////////////////
                            PARTY MANAGER                                                   
    //////////////////////////////////////////////////////////////*/

    /// @notice adds to contributor whitelist
    function whitelistAdd(address _contributor) public {
        require(whitelisted[msg.sender], "NOT_CONTRIBUTOR");

        whitelisted[_contributor] = true;
    }

    /// @notice opens party to any contributors
    function openParty() public {
        require(whitelisted[msg.sender], "NOT_CONTRIBUTOR");

        open == true;
    }

    // @notice increases deadline to new deadline
    // note not used for now — brings up governance concerns
    // function setDeadline(uint _newDeadline) public {
    //     require(deadline < _newDeadline, "CAN'T_DECREASE");

    //     require(deadline + 1 weeks >= _newDeadline, "TOO_FAR");

    //     deadline = _newDeadline;
    // }

    /// @notice transfers nft & burns all tokens when staked users vote to withdraw nft
    /// @notice transfers nft & burns all tokens when staked sole-owner withdraws nft
    function withdraw(address newOwner) public {
        require(msg.sender == address(manager), "NOT_MANAGER");

        nft.safeTransferFrom(address(this), newOwner, id);

        _burn(address(manager), totalSupply);
    }

    /// @notice tranfers nft & burns all tokens when un-staked sole-owner withdraws nft
    /// note secure while using tx.origin because SudoPartyManager requires msg.sender be owner
    function withdrawUnstaked(address newOwner) public {
        require(balanceOf[tx.origin] == totalSupply, "NOT_OWNER");

        require(msg.sender == address(manager), "NOT_MANAGER");

        nft.safeTransferFrom(address(this), newOwner, id);

        _burn(tx.origin, totalSupply);
    }

    /// @notice sets party permissions at SudoParty construction
    function setWhitelist(address[] memory _whitelist) private {
        uint length = _whitelist.length;

        open = length == 0 ? true : false;

        if(!open) {
            for(uint i; i < length; i++) {
                whitelisted[_whitelist[i]] = true;
            }
        }
    }
}