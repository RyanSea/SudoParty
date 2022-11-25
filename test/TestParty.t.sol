// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// import "./utils/Utils.sol";

// import "src/SudoPartyTest.sol";

// import "openzeppelin/token/ERC721/IERC721.sol";

// // forge test --match-contract TestParty --rpc-url $RINKEBY_RPC_URL --chain-id 4  -vvv

// contract TestParty is Test {
//     SudoPartyTest public test;

//     Utils public utils;

//     address payable[] public users;

//     address public ryan;

//     IERC721 public nft;


//     function setUp() public {
//         test = new SudoPartyTest();

//         nft = IERC721(0x9c70d80558b17a558a33F9DFe922FfF7FBf19AE2);

//         utils = new Utils();
//         users = utils.createUsers(1);

//         ryan = users[0];
//     }

//     function testBuy() public {
//         vm.prank(ryan);
//         (bool sent, bytes memory data) = payable(test).call{ value : 10 ether }("");

//         console.log(sent);

//         assertEq(address(test).balance, 10 ether);

//         test.buy();

//         assertEq(nft.ownerOf(10), address(test));
//         console.log("Owns 10");

//         assertEq(nft.ownerOf(9), address(test));
//         console.log("Owns 9");
//     }
// }