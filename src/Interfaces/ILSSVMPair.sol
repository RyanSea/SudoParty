// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lssvm/bonding-curves/CurveErrorCodes.sol";

interface ILSSVMPair {

    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    function swapTokenForSpecificNFTs(
        uint256[] calldata nftIds,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable returns (uint256 inputAmount);

    function getBuyNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 inputAmount,
            uint256 protocolFee
        );
}