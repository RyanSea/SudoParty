// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC721/IERC721.sol";

import "lssvm/LSSVMPair.sol";
import "lssvm/ILSSVMPairFactoryLike.sol";
import "lssvm/bonding-curves/CurveErrorCodes.sol";
import "lssvm/bonding-curves/ICurve.sol";

contract LSSVMRouter {

    /*///////////////////////////////////////////////////////////////
                              INITIALIZATION
    ///////////////////////////////////////////////////////////////*/

    ILSSVMPairFactoryLike public immutable factory;

    constructor(ILSSVMPairFactoryLike _factory) {
        factory = _factory;
    }

    /*///////////////////////////////////////////////////////////////
                              ROUTER PARAMS
    ///////////////////////////////////////////////////////////////*/ 

    struct PairSwapSpecific {
        LSSVMPair pair;
        uint256[] nftIds;
    }

    struct RobustPairSwapSpecific {
        PairSwapSpecific swapList;
        uint128 expectedSpotPrice;
        uint128 maxSpotPrice;
        uint128 maxDelta;
    }

    /*///////////////////////////////////////////////////////////////
                             CONTRACT PARAMS
    ///////////////////////////////////////////////////////////////*/ 

    function _getFillableIdsAndCost(
        RobustPairSwapSpecific memory swapList
    ) internal returns (PairSwapSpecifc memory swapList, uint256 cost) {
        address pair = swapList.swapList.pair;
        uint128 delta = LSSVMPair(pair).delta();
        uint128 spotPrice = LSSVMPair(pair).spotPrice();

        require(delta <= swapList.maxDelta, "DELTA_TOO_HIGH");

        require(spotPrice <= swapList.maxSpotPrice, "SPOTPRICE_TOO_HIGH");

        uint[] ids = swapList.swapList.nftIds;
        IERC721 nft = LSSVMPair(pair).nft();
        uint length = ids.length;

        for(uint i; i < length; ) {
            if(nft.ownerOf(ids[i]) != pair) {
                // move last item of array to index & decrement length
                unchecked { ids[i] = ids[--length]; }

                // remove last item of array
                assembly { mstore(ids, sub(mload(ids), 1)) }
            } else {
                unchecked { ++i; }
            }
        }
        
        cost = LSSVMPair(pair).getBuyNFTQuote(length);
    }

}