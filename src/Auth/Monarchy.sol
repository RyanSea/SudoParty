// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

/// @notice Minimal Auth with a Kingly aesthetic
abstract contract Monarchy {
    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    event NewKing(address newKing);

    address public king;

    constructor() {
        king = msg.sender;

        emit NewKing(king);
    }

    /*//////////////////////////////////////////////////////////////
                            COMMANDS
    //////////////////////////////////////////////////////////////*/
    
    modifier ruled() virtual {
        require(msg.sender == king, "NOT_KING");

        _;
    }

    function annoint (address newKing) public virtual ruled {
        king = newKing;

        emit NewKing(newKing);
    }
}