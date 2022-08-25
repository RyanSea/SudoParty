// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Interfaces/ILSSVMRouter.sol";

import "lssvm/LSSVMPair.sol";

import "openzeppelin/token/ERC721/IERC721.sol";

import "openzeppelin/token/ERC721/IERC721Receiver.sol";

/// @notice meant to test SudoParty buying functionality
contract SudoswapBuyer is IERC721Receiver {

    //======== Initialization ========//
    
    constructor(){}

    ILSSVMRouter public constant router = ILSSVMRouter(0x9ABDe410D7BA62fA11EF37984c0Faf2782FE39B5);

    LSSVMPair public constant pool = LSSVMPair(0x7fF12c0a2599974e1e8d61AE61D5134eca7062fC);

    IERC721 public constant nft = IERC721(0xf9d11e19B417D08Cfa2EA2F217Fc30aE1abB71d3);

    uint public constant id = 12;

    uint public counter;

    //======== Buy ========//

    function buy() public payable returns (uint unused){
        // initialize PairSwapSpecifc
        ILSSVMRouter.PairSwapSpecific memory swap;

        swap.pair = LSSVMPair(pool);
        swap.nftIds = new uint[](1);
        swap.nftIds[0] = id;

        // initialize PairSwapSpecifc[] which is a param for buying nft's by id
        ILSSVMRouter.PairSwapSpecific[] memory pairList = new ILSSVMRouter.PairSwapSpecific[](1);

        pairList[0] = swap;

        counter++;

        // attempt to buy
        unused = router.swapETHForSpecificNFTs {value: balance()} (
            pairList, 
            payable(address(this)), 
            address(this), 
            block.timestamp + 240 // deadline
        );
    }

    //======== NFT ========//

    function onERC721Received(
        address, 
        address, 
        uint, 
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
 
    //======== ETH ========//

    function withdraw() public {
        payable(msg.sender).transfer(balance());
    }

    function balance() public view returns (uint eth) {
        eth = address(this).balance;
    }

    receive() external payable {}
}
