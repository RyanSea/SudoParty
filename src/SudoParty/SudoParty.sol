// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../Interfaces/ILSSVMPair.sol";
import "../Interfaces/ILSSVMRouter.sol";
import "../Interfaces/ILSSVMPairFactory.sol";

/// @dev added name() and symbol() to IERC721.sol
import "openzeppelin/token/ERC721/IERC721.sol";

import "solmate/tokens/ERC20.sol";

import "../Interfaces/ISudoPartyManager.sol";

import "openzeppelin/token/ERC721/IERC721Receiver.sol";

import "Monarchy/";

/// @title SudoParty!
/// @author Autocrat (Ryan)
/// @notice buys and fractionalizes nft's from Sudoswap
/// @author modified from PartyBid
abstract contract SudoParty is ERC20, IERC721Receiver, Monarchy {

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/ 
    
    /// @notice address => if its on whitelist
    mapping (address => bool) public whitelisted;

    /// @notice deadline for SudoParty to complete purchase
    uint public immutable deadline;

    /// @notice 0 - 100 (%)| quorum needed to pass a yes vote
    uint public immutable quorum;

    /// @notice Sudoswap factory
    ILSSVMPairFactory public immutable factory;

    /// @notice Sudoswap router
    ILSSVMRouter public immutable router;

    /// @notice if party is open to any contributors
    bool public open;

    /// @notice SudoParty Manager
    address public manager;

    /// @notice successful purchase
    bool public success;

    enum Status { 
        active, 
        finalized
    }

    struct Contribution {
        uint amount;
        uint totalContributions;
    }

    receive() external payable{}

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
  
    /// @notice adds to contributor whitelist
    function whitelistAdd(address sender, address _contributor) public {
        require(whitelisted[sender], "NOT_CONTRIBUTOR");

        whitelisted[_contributor] = true;
    }

    /// @notice opens party to any contributors
    function openParty(address sender) public {
        require(whitelisted[sender], "NOT_CONTRIBUTOR");

        open = true;
    }

    /// @notice adds msg.sender's contribution
    function contribute(address sender) public payable {
        require(status == Status.active, "PARTY_CLOSED");

        require(open || whitelisted[sender], "NOT_MEMBER");

        uint amount = msg.value;
        
        require(amount > 0, "CONTRIBUTION_TOO_LOW");

        // create contribution struct 
        Contribution memory contribution = Contribution(amount, partybank);

        // push to user contributions holder
        contributions[sender].push(contribution);

        // add amount to user contributions counter 
        totalUserContribution[sender] += amount;

        // add amount to total contributed to party
        partybank += amount;

        emit NewContribution(sender, amount, totalUserContribution[sender], partybank);
    }

    /// @notice mints tokens & creates SudoPartyManager if purchase succeeded
    /// @notice finalizes party if purchase succeeded or deadline passed
    function finalize() public {
        require(status == Status.active, "PARTY_FINALIZED");

        if (success) {
            status = Status.finalized;

            spent = partybank - address(this).balance;

            _mint(address(this), spent);

        } else if (block.timestamp >= deadline) {
            status = Status.finalized;
        }

        if(status == Status.finalized) emit Finalized(success);
    }

    /// @notice returns user's claimable assets if party is finaized
    /// todo ensure non re-entry
    function claim(address contributor) public returns (uint eth, uint tokens) {
        require(status == Status.finalized, "NOT_FINALIZED");

        require(totalUserContribution[contributor] > 0, "NO_CONTRIBUTION");

        require(!claimed[contributor], "ALREADY_CLAIMED");

        claimed[contributor] = true;

        // _spent = tokens to give, _unspent = eth to return
        (tokens, eth) = ethSpent(contributor);

        if (eth > 0) payable(contributor).transfer(eth);

        if (tokens > 0) {
            allowance[address(this)][msg.sender] += tokens;

            transferFrom(address(this), contributor, tokens);
        }

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
        
        // load total spent on nft to memory
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
        }

        // if 0 is spent on nft then _spent is 0
        _unspent = totalUserContribution[contrbutor] - _spent;
    }

    /*///////////////////////////////////////////////////////////////
                                SUDO QUERY                                                    
    //////////////////////////////////////////////////////////////*/

    /// @notice sets price to current spot price and returns price
    // function getPrice() public returns (uint) {
    //     require(isListed(), "NOT_LISTED");

    //     (, uint newSpotPrice,,,) = pool.getBuyNFTQuote(1);

    //     return price = newSpotPrice;
    // }

    /*///////////////////////////////////////////////////////////////
                              PARTY MANAGER                                                   
    //////////////////////////////////////////////////////////////*/
    
    /// @notice sets SudoParty Manager
    /// @dev set by SudoPartyHub at SudoParty creation
    function setManager(address _manager) public ruled {
        manager = _manager;
    }

    /// @notice allow manager to move amount from account
    function allow(uint amount, address account) public {
        require(msg.sender == address(manager), "NOT_MANAGER");

        allowance[account][account] += amount;
    }

    /// @notice burns tokens 
    /// @dev used on withdraw and claiming relist sale
    function burn(address from, uint amount) public {
        require(msg.sender == address(manager), "NOT_MANAGER");

        _burn(from, amount);
    }

    /// @notice sets party permissions at SudoParty construction
    function setWhitelist(address[] memory _whitelist) internal {
        uint length = _whitelist.length;

        open = length == 0 ? true : false;

        if(!open) {
            for(uint i; i < length; i++) {
                whitelisted[_whitelist[i]] = true;
            }
        }
    }

    function onERC721Received(
        address, 
        address, 
        uint, 
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}