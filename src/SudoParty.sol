// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lssvm/LSSVMPair.sol";

import "lssvm/ILSSVMPairFactoryLike.sol";

import "openzeppelin/token/ERC721/IERC721.sol";

import "openzeppelin/utils/Strings.sol";

import "solmate/tokens/ERC20.sol";

/// @title SudoParty!
/// @author Autocrat 
/// @notice buys and fractionalizes nft's from sudoswap
/// @author modified from PartyBid
contract SudoParty is ERC20 {

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/ 

    LSSVMPair public immutable pool;

    IERC721 public immutable nft;

    uint public immutable id;

    constructor(
        LSSVMPair _pool, 
        IERC721 _nft, 
        uint _id
    ) ERC20(
        string(abi.encodePacked(_nft.name(), String.toString(_id), "Vault")),
        string(abi.encode(_nft.symbol(), String.toString(_id))),
        18
    ){
        pool = _pool;
        nft = _nft;
        id = _id;

        status = Status.active;
    }

    /// @notice 100 tokens per .001 ether
    uint public constant token_scale = 100;

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
                            STATE VARIABLES
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
                            PROTOCOL FUNCTIONS
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

    function buy(address pool, uint id) public {
        require(status == Status.active, "PARTY_CLOSED");

        status = Status.closed;

        ILSSVMRouter.PairSwapSpecific memory swap;

        swap.pair = LSSVMPair(pool);
        swap.nftIds = new uint[](1);
        swap.nftIds[0] = id;

        ILSSVMRouter.PairSwapSpecific[] memory pairList = new ILSSVMRouter.PairSwapSpecific[](1);

        pairList[0] = swap;

        getPrice();

        market.swapETHForSpecificNFTs(
            pairList, 
            payable(address(this)), 
            address(this), 
            block.timestamp + 180 // deadline
        );

        spent = price;
    }

    function finalize() public {
        require(status == Status.closed, "NOT_FINALIZE_READY");

        bool complete = nft.ownerOf(id) == address(this);

        if (complete) {
            status = Status.finalized;

            unpent = address(this).balance;

            uint memory tokens = spent / .001 ether * token_scale;
        } 
    }

    function claim(address contributor) public {
        require(status == Status.finalized, "NOT_FINALIZED");

        require(totalUsercontribution[contributor] > 0, "NO_CONTRIBUTION");

        require(!claimed[contributor], "ALREADY_CLAIMED");

        claimed[contributor] = true;


    }

    /*///////////////////////////////////////////////////////////////
                                ACCOUNTING                                                   
    //////////////////////////////////////////////////////////////*/

    function getClaimAmount(address contributor) public view returns (uint tokens, uint eth) {
        if (spent > 0) {

        } else {
            eth = totalUsercontribution[contributor];
        }
    }

    function ethUsed(address contrbutor) public view returns (uint eth) {

    }

    /*///////////////////////////////////////////////////////////////
                                POOL QUERY                                                    
    //////////////////////////////////////////////////////////////*/

    function isListed() public view returns (bool listed) {
        listed = ILSSVMPairFactoryLike(0x9ABDe410D7BA62fA11EF37984c0Faf2782FE39B5)
            .isPair(pool, ILSSVMPairFactoryLike.PairVariant.ENUMERABLE_ETH);

        if(listed) listed = nft.ownerOf(id) == pool;
    }

    function getPrice() public returns (uint) {
        require(isListed(), "NOT_LISTED");

        (, uint newSpotPrice,,,) = pool.getBuyNFTQuote(1);

        return price = newSpotPrice;
    }
    
}