// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Interfaces/ILSSVMRouter.sol";

import "./Interfaces/IMarketWrapper.sol";

import "lssvm/ILSSVMPairFactoryLike.sol";

import "lssvm/LSSVMPair.sol";

import {ERC721} from "solmate/tokens/ERC721.sol";

/// TODO Allow for the buying of mutliple nft's / integrate all of sudoswap's functionality
contract SudoswapMarketWrapper is IMarketWrapper {
    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/ 

    ILSSVMRouter public immutable market;

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

    function getPrice(address pool) public view returns (uint price) {
        (   , 
            uint newSpotPrice,
            uint newDelta,
            uint inputAmount,
            uint protocolFee
        ) = LSSVMPair(pool).getBuyNFTQuote(1);

        price = newSpotPrice;
    }

    /// TODO allow for the b
    function buy(address pool, uint id) public payable returns(uint unspent) {

    }


    /*///////////////////////////////////////////////////////////////
                    UNIMPLEMENTED FUNCTIONS & CORRELATES 
    //////////////////////////////////////////////////////////////*/ 

    /// @notice correlated to isListed
    function auctionIdMatchesToken(
        uint256 auctionId,
        address nftContract,
        uint256 tokenId
    ) public virtual view returns (bool);

    /// @notice correlated to getPrice
    function getMinimumBid(uint256 auctionId) public virtual view returns (uint256);
    function getCurrentHighestBidder(uint256 auctionId) public virtual view returns (address);

    /// @notice correlated to buy
    function bid(uint256 auctionId, uint256 bidAmount) public virtual;


}