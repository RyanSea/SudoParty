// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Interfaces/ILSSVMRouter.sol";

import "./Interfaces/IMarketWrapper.sol";

import "lssvm/ILSSVMPairFactoryLike.sol";

import "lssvm/LSSVMPair.sol";

import {ERC721} from "solmate/tokens/ERC721.sol";

/// TODO Allow for the buying of mutliple nft's / integrate all of sudoswap's functionality
/// TODO figure out deadline in function buy
contract SudoswapMarketWrapper is IMarketWrapper {
    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/ 

    ILSSVMRouter public immutable market;

    bool public finalized;

    constructor(address _LSSVMRouter) {
        market = ILSSVMRouter(_LSSVMRouter);
    }

    /*///////////////////////////////////////////////////////////////
                            SUDOSWAP FUNCTIONS
    //////////////////////////////////////////////////////////////*/ 

    function isListed(
        address pool, 
        address nft, 
        uint id
    ) public view returns (bool listed) {
        listed = ILSSVMPairFactoryLike(0x9ABDe410D7BA62fA11EF37984c0Faf2782FE39B5)
            .isPair(pool, ILSSVMPairFactoryLike.PairVariant.ENUMERABLE_ETH);

        if(listed) listed = ERC721(nft).ownerOf(id) == pool;
    }

    /// @notice gets spot price of pool based on uint256 of pool address
    function getPrice(address pool) public view returns (uint price) {
        (, uint newSpotPrice,,,) = LSSVMPair(pool).getBuyNFTQuote(1);

        price = newSpotPrice;
    }

    function buy(address pool, uint id) external {
        ILSSVMRouter.PairSwapSpecific memory swap;

        swap.pair = LSSVMPair(pool);
        swap.nftIds = new uint[](1);
        swap.nftIds[0] = id;

        ILSSVMRouter.PairSwapSpecific[] memory pairList = new ILSSVMRouter.PairSwapSpecific[](1);

        pairList[0] = swap;

        market.swapETHForSpecificNFTs(
            pairList, 
            payable(msg.sender), 
            msg.sender, 
            block.timestamp + 180 // deadline
        );
    }

    /*///////////////////////////////////////////////////////////////
                   UNIMPLEMENTED FUNCTIONS & CORRELATES 
    //////////////////////////////////////////////////////////////*/ 

    /// @notice correlated to isListed
    function auctionIdMatchesToken(
        uint256 auctionId,
        address nftContract,
        uint256 tokenId
    ) public virtual view returns (bool){}

    /// @notice correlated to getPrice
    function getMinimumBid(uint256 auctionId) public virtual override view returns (uint256){}

    /// @notice not needed — not an auction
    function getCurrentHighestBidder(uint256 auctionId) public virtual override view returns (address){}

    /// @notice correlated to buy
    function bid(uint256 auctionId, uint256 bidAmount) external{}
    
    /// @notice not needed — not an auction
    function isFinalized(uint256) external pure returns (bool){}

    /// @notice not needed — not an auction
    function finalize(uint256) external {}
}