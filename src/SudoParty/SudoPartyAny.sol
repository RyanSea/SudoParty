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

    /// @notice attempts to buy nfts from pairList
    function buy() public {
        updatePairList();

        uint unspent = router.swapETHForAnyNFTs {value: partybank} (
            pairList, 
            payable(address(this)), 
            manager, 
            block.timestamp + 240 // swap deadline
        );

        success = true;

        emit PartyWon(spent, unspent);
    }

    /// @notice removes any sold nfts from pairList
    function updatePairList() public {
        ILSSVMRouter.PairSwapAny[] memory swaps = pairList;

        uint length = pairList.length;

        uint amount;

        uint numItems;

        // iterate through swaps
        for (uint i; i < length; ) {
            amount = swaps[i].pair.getAllHeldIds().length;

            numItems = swaps[i].numItems;

            // if amount of nft's in pool >= nfts to buy, iterate
            if (amount >= numItems) {
                unchecked { ++i; }

            // if there are no nft's in pool, remove pairSwapAny item
            } else if (amount == 0) {
                unchecked { swaps[i] = swaps[--length]; }

                assembly { mstore(swaps, sub(mload(swaps), 1)) }

            // if less nft's in pool than nft's to buy, set numItems to nft's in pool & iterate
            } else if (amount < numItems) {
                swaps[i].numItems = amount;

                unchecked { ++i; }
            }
        }

        // update pairList
        pairList = swaps;
    }
}