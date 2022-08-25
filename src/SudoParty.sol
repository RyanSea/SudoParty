// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lssvm/LSSVMPair.sol";

import "./Interfaces/ILSSVMRouter.sol";

/// @dev added name() and symbol() to IERC721.sol
import "openzeppelin/token/ERC721/IERC721.sol";

import "openzeppelin/utils/Strings.sol";

import "solmate/tokens/ERC20.sol";

/// @title SudoParty!
/// @author Autocrat (Ryan)
/// @notice buys and fractionalizes nft's from Sudoswap
/// @author modified from PartyBid
contract SudoParty is ERC20 {

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/ 

    ILSSVMRouter public immutable router;

    LSSVMPair public immutable pool;

    IERC721 public immutable nft;

    uint public immutable deadline;

    uint public immutable id;

    constructor(
        address _router,
        address _pool, 
        address _nft, 
        uint deadline,
        uint _id

        //symbol e.g. PUNK6529
    ) ERC20(
        string(abi.encodePacked(IERC721(_nft).name(), Strings.toString(_id), "Fraction")),
        string(abi.encode(IERC721(_nft).symbol(), Strings.toString(_id))),
        18
    ){
        router = ILSSVMRouter(_router);
        pool = LSSVMPair(_pool);
        nft = IERC721(_nft);
        id = _id;

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

    /// @notice total contributed
    uint public contributed;

    /// @notice current status of party
    Status public status;

    /// @notice SudoParty Manager
    address public manager;

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

    event PartyWon(uint cost, uint unspent);

    /*///////////////////////////////////////////////////////////////
                            SUDOPARTY FUNCTIONS
    //////////////////////////////////////////////////////////////*/ 

    /// @notice adds msg.sender's contribution and accounts for it
    function contribute() public payable {
        require(status == Status.active, "PARTY_CLOSED");

        uint amount = msg.value;

        require(amount + contributed <= getPrice() + 0.5 ether, "CONTRIBUTION_TOO_HIGH");
        
        require(amount > 0, "CONTRIBUTION_TOO_LOW");

        // create contribution struct 
        Contribution memory contribution = Contribution(amount, contributed);

        // push to user contributions holder
        contributions[msg.sender].push(contribution);

        // add amount to user contributions counter 
        totalUserContribution[msg.sender] += amount;

        // add amount to total contributed to party
        contributed += amount;

        emit NewContribution(msg.sender, amount, totalUserContribution[msg.sender], contributed);
    }

    /// @notice attempts to buy nft, unused eth is returned to contract
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
        assert(contributed >= price);

        // attempt to buy
        uint unspent = router.swapETHForSpecificNFTs {value: price} (
            pairList, 
            payable(address(this)), 
            address(this), 
            block.timestamp + 240 // deadline
        );

        spent = price;

        status = Status.closed;

        emit PartyWon(spent, unspent);
    }

    /// @notice mints tokens & closes party if purchase succeeded
    function finalize() public {
        require(status == Status.closed, "NOT_FINALIZE_READY");

        bool complete = nft.ownerOf(id) == address(this);

        if (complete) {
            status = Status.finalized;

            _mint(address(this), spent);

        } else if (block.timestamp >= deadline) {
            status = Status.finalized;
        }
    }

    /// @notice returns user's claimable assets
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
    function ethSpent(address contrbutor) public view returns (uint _spent, uint _unspent) {
        
        uint totalSpent = spent;

        uint totalContributions = contributions[contrbutor].length;

        uint _amount;

        Contribution memory contribution;

        if (totalSpent > 0) {

            for(uint i; i < totalContributions; i++) {
                contribution = contributions[contrbutor][i];

                _amount = contribution.amount + contribution.totalContributions <= totalSpent ?
                    contribution.amount : contribution.totalContributions < totalSpent ?
                        totalSpent - contribution.totalContributions : 0;
                
                // if 0 eth was contributed, any subsequent contributions are meaningless
                if (_amount == 0) break;

                _spent += _amount;
            }

        }

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

    function withdraw() public {
        require(msg.sender == manager, "NOT_MANAGER");

        _burn(manager, totalSupply);
    }
}