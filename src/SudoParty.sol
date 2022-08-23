// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lssvm/LSSVMPair.sol";

import "./Interfaces/ILSSVMRouter.sol";

/// @dev added name() and symbol() to IERC721.sol
import "openzeppelin/token/ERC721/IERC721.sol";

import "openzeppelin/utils/Strings.sol";

import "solmate/tokens/ERC20.sol";

/// @title SudoParty!
/// @author Autocrat 
/// @notice buys and fractionalizes nft's from Sudoswap
/// @author modified from PartyBid
contract SudoParty is ERC20 {

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/ 

    ILSSVMRouter public immutable router;

    LSSVMPair public immutable pool;

    IERC721 public immutable nft;

    uint public immutable id;

    constructor(
        ILSSVMRouter _router,
        LSSVMPair _pool, 
        IERC721 _nft, 
        uint _id
    ) ERC20(
        string(abi.encodePacked(_nft.name(), Strings.toString(_id), "Vault")),
        string(abi.encode(_nft.symbol(), Strings.toString(_id))),
        18
    ){
        router = _router;
        pool = _pool;
        nft = _nft;
        id = _id;

        status = Status.active;
    }

    /// @notice 100 tokens per .001 ether
    uint public constant token_scale = 100;

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

    /// @notice remaining eth after purchase
    uint public unspent;

    /// @notice total contributed
    uint public contributed;

    /// @notice current status of party
    Status public status;

    /// @notice contributor => whether or not they claimed
    mapping(address => bool) public claimed;

    /// @notice user contributions counter
    mapping (address => uint) public totalUsercontribution;

    /// @notice user contributions holder
    mapping (address => Contribution[]) public contributions;

    /*///////////////////////////////////////////////////////////////
                            SUDOPARTY FUNCTIONS
    //////////////////////////////////////////////////////////////*/ 

    /// @notice adds msg.sender's contribution and accounts for it
    function contribute() public payable {
        require(status == Status.active, "PARTY_CLOSED");

        address contributor = msg.sender;

        uint amount = msg.value;

        require(amount + contributed <= getPrice() + 0.5 ether, "CONTRIBUTION_TOO_HIGH");
        
        require(amount > 0, "CONTRIBUTION_TOO_LOW");

        // create contribution struct 
        Contribution memory contribution = Contribution(amount, contributed);

        // push to user contributions holder
        contributions[contributor].push(contribution);

        // add amount to user contributions counter 
        totalUsercontribution[contributor] += amount;

        // add amount to total contributed to party
        contributed += amount;
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

        assert(contributed >= price);

        // attempt to buy
        router.swapETHForSpecificNFTs {value: price} (
            pairList, 
            payable(address(this)), 
            address(this), 
            block.timestamp + 240 // deadline
        );

        status = Status.closed;
    }

    /// @notice mints tokens & closes party for successful purchase
    function finalize() public {
        require(status == Status.closed, "NOT_FINALIZE_READY");

        bool complete = nft.ownerOf(id) == address(this);

        if (complete) {
            status = Status.finalized;

            unspent = address(this).balance;

            uint tokens = spent / .001 ether * token_scale;

            _mint(address(this), tokens);
        }
    }

    /// @notice returns user's claimable assets
    /// @notice allows for rage-quitting 
    /// ToDo ensure non re-entry
    function claim(address contributor) public {
        require(totalUsercontribution[contributor] > 0, "NO_CONTRIBUTION");

        require(!claimed[contributor], "ALREADY_CLAIMED");

        claimed[contributor] = true;

        (uint tokens, uint eth) = getClaimAmount(contributor);

        if (eth > 0) payable(contributor).transfer(eth);

        if (tokens > 0) transfer(contributor, tokens);
    }

    /*///////////////////////////////////////////////////////////////
                            CONTRIBUTOR ACCOUNTING                                                   
    //////////////////////////////////////////////////////////////*/

    function getClaimAmount(address contributor) public view returns (uint tokens, uint eth) {
        if (spent > 0) {
            eth = ethUsed(contributor);

            tokens = eth / .001 ether * token_scale;

        } else {
            eth = totalUsercontribution[contributor];
        }
    }

    function ethUsed(address contrbutor) public view returns (uint eth) {
        uint totalSpent = spent;

        uint totalContributions = contributions[contrbutor].length;

        uint _amount;

        Contribution memory contribution;

        for(uint i; i < totalContributions; i++) {
            contribution = contributions[contrbutor][i];

            _amount = contribution.amount + contribution.totalContributions <= totalSpent ?
                contribution.amount : contribution.totalContributions < totalSpent ?
                    totalSpent - contribution.totalContributions : 0;
            
            if (_amount == 0) break;

            eth += _amount;
        }
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
}