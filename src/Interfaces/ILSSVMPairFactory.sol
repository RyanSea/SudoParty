// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lssvm/ILSSVMPairFactoryLike.sol";

import "openzeppelin/token/ERC721/IERC721.sol";

import "lssvm/bonding-curves/ICurve.sol";

import "lssvm/LSSVMPairETH.sol";

import "lssvm/LSSVMPair.sol";


interface ILSSVMPairFactory is ILSSVMPairFactoryLike {
    function createPairETH(
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        LSSVMPair.PoolType _poolType,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) external payable returns (LSSVMPairETH pair);
}