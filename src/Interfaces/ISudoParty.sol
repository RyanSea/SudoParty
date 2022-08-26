// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC721/IERC721.sol";

interface ISudoParty {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function nft() external view returns (IERC721);

    function spent() external view returns (uint);

    function consensus() external view returns (uint);

    function id() external view returns (uint);

    function withdraw() external;

    function withdrawUnstaked() external;
}