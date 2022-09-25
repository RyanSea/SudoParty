// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./SudoParty.sol";


contract SudoPartySpecific is SudoParty {

    ILSSVMRouter.PairSwapSpecific[] public pairList;

    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory whitelist,
        uint _deadline,
        uint _quorum,
        address _factory,
        address _router,
        ILSSVMRouter.PairSwapSpecific[] memory _pairList
    ) ERC20( _name, _symbol, 18) {
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

    /// @notice updates pairList & attempts to buy nfts
    function buy() public {
        updatePairList();

        uint unspent = router.swapETHForSpecificNFTs {value: partybank} (
            pairList, 
            payable(address(this)), 
            manager, 
            block.timestamp + 240 // swap deadline
        );

        success = true;

        emit PartyWon(spent, unspent);
    }

    /// @notice compares held ids from pool & adjusts ids from corresponding PairSwapSpecific instance
    function updatePairList() public {
        ILSSVMRouter.PairSwapSpecific[] memory swaps = pairList;

        IERC721 nft;

        uint _i;

        uint amount;

        address pool;

        uint length = swaps.length;

        // iterate through swaps
        for (uint i; i < length; ) {
            pool = address(swaps[i].pair);

            nft = swaps[i].pair.nft();

            amount = swaps[i].nftIds.length;

            // iterate through nftIds
            for (_i = 0; i < amount; ) {
                // if pool is not owner of id, assign index to last item and remove last item
                if (nft.ownerOf(swaps[i].nftIds[_i]) != pool) {
                    swaps[i].nftIds[_i] = swaps[i].nftIds[unchecked { --amount }];

                    assembly { mstore(swaps[i].nftIds, sub(mload(swaps[i].nftIds), 1)) }

                } else {
                    unchecked { ++_i }
                }
            }

            // if no nftIds exist in pool, remove PairSwapSpecific item using same method
            if (amount == 0) {
                swaps[i] = swaps[unchecked { --length }];

                assembly { mstore(swaps, sub(mload(swaps), 1)) }
            
            } else {
                unchecked { ++_i }
            }
        }

        // update pairList
        pairList = swaps;
    }
}