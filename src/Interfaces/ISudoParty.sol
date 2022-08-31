// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC721/IERC721.sol";

import "./ILSSVMPairFactory.sol";

interface ISudoParty {
    //======== SudoParty View ========//

    function nft() external view returns (IERC721);

    function spent() external view returns (uint);

    function consensus() external view returns (uint);

    function factory() external view returns (ILSSVMPairFactory);

    function id() external view returns (uint);

    //======== SudoParty Functions ========//

    function setManager(address manager) external;

    function whitelistAdd(address contributor) external;

    function openParty() external;

    function contribute() external payable;

    function buy() external;

    function finalize() external;

    function claim(address contriutor) external;

    //======== SudoParty Manager Functions ========//

    function claimSale(uint _amount) external;

    function burn(address from, uint amount) external;

    function allow(uint amount, address account) external;

    //======== ERC-20 ========//

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint);

    function balanceOf(address _address) external view returns (uint);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}