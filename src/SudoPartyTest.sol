// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//import "./Interfaces/ILSSVMPair.sol";
import "./Interfaces/ILSSVMRouter.sol";
//import "./Interfaces/ILSSVMPairFactory.sol";

import "openzeppelin/token/ERC721/IERC721Receiver.sol";

contract SudoPartyTest is IERC721Receiver {
    ILSSVMRouter immutable router = ILSSVMRouter(0x9ABDe410D7BA62fA11EF37984c0Faf2782FE39B5);

    ILSSVMPair immutable pair = ILSSVMPair(0xbc1703Cc4295Acefb7FbC1Cd107146eD8AfBE4dD);

    ILSSVMRouter.PairSwapSpecific[] public swapList;

    constructor(){
        ILSSVMRouter.PairSwapSpecific memory _swap;

        uint[] memory ids = new uint[](2);
        ids[0] = 10;
        ids[1] = 9;

        _swap.pair = pair;
        _swap.nftIds = ids;

        swapList.push(_swap);
    }

    receive() external payable{}

    function buy() public {
        router.swapETHForSpecificNFTs { value: address(this).balance } (
            swapList, 
            payable(address(this)), 
            address(this), 
            block.timestamp + 240 
        );
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