// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./SudoParty.sol";

contract SudoPartyAny is SudoParty {

    ILSSVMRouter.PairSwapAny[] public pairList;

    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory whitelist,
        uint _deadline,
        uint _quorum,
        address _factory,
        address _router,
        ILSSVMRouter.PairSwapAny[] memory _pairList
    ) ERC20(_name, _symbol, 18) {
        setWhitelist(whitelist);

        deadline = _deadline;
        quorum = _quorum;
        factory = ILSSVMPairFactory(_factory);
        router = ILSSVMRouter(_router);

        uint length = _pairList.length;

        for (uint i; i < length; ++i) {
            pairList[i] = _pairList[i];
        }
    }

    function updatePairList() public {
        ILSSVMRouter.PairSwapAny memory swap;

        uint length = pairList.length;

        uint amount;

        uint numItems;

        for (uint i; i < length; ) {
            swap = pairList[i];

            amount = swap.pair.getAllHeldIds().length;

            numItems = swap.numItems;

            if (amount >= numItems) {
                ++i;

            } else if (amount < numItems) {
                swap.numItems = amount;

                pairList[i] = swap;

                ++i;

            } else if (amount == 0) {
                delete pairList[i];

                --i;

                --length;
            }
        }
    }
}