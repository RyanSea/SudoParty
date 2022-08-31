// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "./utils/Utils.sol";

import "src/Factories/PartyFactory.sol";

import "src/Factories/ManagerFactory.sol";

import "src/SudoPartyHub.sol";

import "src/Interfaces/ILSSVMPairFactory.sol";

//import "src/Interfaces/ILSSVMRouter.sol";

// forge test --match-contract SudoPartyTest --rpc-url $RINKEBY_RPC_URL --chain-id 4  -vvv

contract SudoPartyTest is Test {

    SudoPartyHub sudoparty;

    address party;

    ILSSVMRouter router;

    ILSSVMPairFactory factory;

    ILSSVMPair pool;

    IERC721 nft;

    uint id;   

    // SudoPartyManager-created pool
    address relisting;

    Utils internal utils;

    address payable[] internal users;

    address ryan;
    address nich;
    address owen;
    address sharelove;

    enum ProposalType {
        sell,
        set_consensus,
        withdraw
    }

    function setUp() public {
        utils = new Utils();
        users = utils.createUsers(4);

        vm.label(users[0], "Ryan");
        vm.label(users[1], "Nich");
        vm.label(users[2], "Owen");
        vm.label(users[3], "ShareLove");

        ryan = users[0];
        nich = users[1];
        owen = users[2];
        sharelove = users[3];

        router = ILSSVMRouter(0x9ABDe410D7BA62fA11EF37984c0Faf2782FE39B5);

        factory = ILSSVMPairFactory(0xcB1514FE29db064fa595628E0BFFD10cdf998F33);

        pool = ILSSVMPair(0xbc1703Cc4295Acefb7FbC1Cd107146eD8AfBE4dD);

        nft = IERC721(0x9c70d80558b17a558a33F9DFe922FfF7FBf19AE2);

        id = 10;

        address party_factory = address(new PartyFactory());
        address manager_factory = address(new ManagerFactory());

        sudoparty = new SudoPartyHub(party_factory, manager_factory);

    }

    function sudopartyWhitelist() public {
        assertEq(nft.ownerOf(id), address(pool));

        uint deadline = block.timestamp + 1 days;

        address[] memory party = new address[](3);

        party[0] = ryan;
        party[1] = nich;
        party[2] = owen;

        sudoparty.startParty(party, deadline, 33, address(factory), address(router), address(pool), address(nft), id);
    }
   
    // function contribute() public {
    //     vm.prank(ryan);
    //     sudoparty.contribute{value: .5 ether}();
    //     console.log("Ryan contributed .5 ETH");

    //     vm.prank(nich);
    //     sudoparty.contribute{value: 1 ether}();
    //     console.log("Nich contributed 1 ETH");

    //     vm.prank(owen);
    //     sudoparty.contribute{value: 1 ether}();
    //     console.log("Owen contributed 1 ETH");

    //     vm.expectRevert("NOT_MEMBER");
    //     vm.prank(sharelove);
    //     sudoparty.contribute{value: 1 ether}();
    //     console.log("ShareLove was unable to contribute because they weren't whitelisted");
    // }

    // function addAndContribute() public {
    //     vm.prank(ryan);
    //     sudoparty.whitelistAdd(sharelove);
    //     console.log("ShareLove added to List!");

    //     vm.prank(sharelove);
    //     sudoparty.contribute{value: 1 ether}();
    //     console.log("ShareLove contributed 1 eth");
    // }

    // function buy() public {
    //     vm.prank(ryan);
    //     sudoparty.buy();
    // }

    // function finalize() public {
    //     sudoparty.finalize();

    //     //manager = sudoparty.manager();
    //     assertTrue(nft.ownerOf(id) == address(manager));
    //     console.log("NFT Successfully Group Purchased");
    // }

    // function claim() public {
    //     uint _eth;
    //     uint _tokens;

    //     (_eth, _tokens) = sudoparty.claim(ryan);
    //     // console.log("Ryan spent ", _tokens, " ETH and received as many tokens");
    //     // console.log("Ryan had ", _eth, " unspent ETH returned to them");

    //     (_eth, _tokens) = sudoparty.claim(nich);
    //     // console.log("Nich spent ", _tokens, " ETH and received as many tokens");
    //     // console.log("Nich had ", _eth, " unspent ETH returned to them");

    //     (_eth, _tokens) = sudoparty.claim(owen);
    //     // console.log("Owen spent ", _tokens, " ETH and received as many tokens");
    //     // console.log("Owen had ", _eth, " unspent ETH returned to them");

    //     (_eth, _tokens) = sudoparty.claim(sharelove);
    //     // console.log("Sharelove spent ", _tokens, " ETH and received as many tokens");
    //     // console.log("Sharelove had ", _eth, " unspent ETH returned to them");
    // }

    // function stake() public {
    //     vm.startPrank(ryan);
    //     sudoparty.approve(address(manager), sudoparty.balanceOf(ryan));
    //     manager.stake(sudoparty.balanceOf(ryan));
    //     vm.stopPrank();
    //     //console.log("Ryan Staked");

    //     vm.startPrank(nich);
    //     sudoparty.approve(address(manager), sudoparty.balanceOf(nich));
    //     manager.stake(sudoparty.balanceOf(nich));
    //     vm.stopPrank();
    //     //console.log("Nich Staked");

    //     vm.startPrank(owen);
    //     sudoparty.approve(address(manager), sudoparty.balanceOf(owen));
    //     manager.stake(sudoparty.balanceOf(owen));
    //     vm.stopPrank();
    //     //console.log("Owen Staked");

    //     vm.startPrank(sharelove);
    //     sudoparty.approve(address(manager), sudoparty.balanceOf(sharelove));
    //     manager.stake(sudoparty.balanceOf(sharelove));
    //     vm.stopPrank();
    //     //console.log("Sharelove Staked");

    // }

    // function createProposal() public {
    //     vm.prank(ryan);
    //     manager.createProposal(SudoPartyManager.ProposalType.sell, 6 ether, address(0));

    //     console.log("Proposal To Re-List Token Made");
    // }

    // function vote() public {
    //     vm.prank(sharelove);
    //     manager.vote(1, true);

    //     vm.prank(owen);
    //     manager.vote(1, true);

    //     vm.prank(nich);
    //     manager.vote(1, true);

    //     console.log("ShareLove, Owen, & Nich Voted Yes!");
    // }

    // function finalizeVote() public {
    //     vm.prank(ryan);
    //     manager.finalize(1);

    //     relisting = manager.listing();
    //     assertEq(nft.ownerOf(id), address(relisting));
    //     console.log("NFT Successfully Re-Listed!");
    // }

    // function testWhitelist() public {
    //     sudopartyWhitelist();

    //     bool ryanListed = sudoparty.whitelisted(ryan);
    //     bool nichListed = sudoparty.whitelisted(nich);
    //     bool owenListed = sudoparty.whitelisted(owen);

    //     assertTrue(ryanListed && nichListed && owenListed);
    //     assertTrue(sudoparty.whitelisted(sharelove) == false);

    //     console.log("Nich, Ryan, & Owen Successfully Whitelisted");
    // }

    // function testContribute() public {
    //     sudopartyWhitelist();
    //     contribute();
    //     addAndContribute();
    //     buy();
    //     finalize();
    //     claim();
    //     stake();
    //     createProposal();
    //     vote();
    //     finalizeVote();
    // }

}
