// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./SudoParty.sol";


contract SudoPartySpecific is SudoParty {

    ILSSVMRouter.PairSwapSpecific[] public pairList;

    constructor(
        string calldata _name,
        string calldata _symbol,
        address[] memory whitelist,
        uint _deadline,
        uint _quorum,
        address _factory,
        address _router,
        ILSSVMRouter.PairSwapSpecifc[] memory _pairList
    ) ERC20( _name, _symbol, 18) {
        setWhitelist(whitelist);

        deadline = _deadline;
        quorum = _quorum;
        factory = _factory;
        router = _router;

        uint length = _pairList.length;

        for (uint i; i < length; ++i) {
            pairList[i] = _pairList[i];
        }
    }

    // nft id => bool
    mapping (uint => bool) public exists;

    function buy() public {
        uint unspent = router.swapETHForSpecificNFTs {value: partybank} (
            pairList, 
            payable(address(this)), 
            manager, 
            block.timestamp + 240 // swap deadline
        );

        emit PartyWon(spent, unspent);
    }

    /// @notice compares held ids from pool & adjusts ids from corresponding PairSwapSpecific instance
    function updatePairList() public {
        ILSSVMRouter.PairSwapSpecific swap;

        uint[] poolIds;

        uint[] nftIds;

        uint[] ids;

        uint amount;

        uint length = pairList.length;

        uint _i;

        for (uint i; i < length; ) {
            swap = pairList[i];

            poolIds = swap.pair.getAllHeldIds();

            amount = poolIds.length;

            // iterate through pool ids and assign true to each
            for (_i = 0; i < amount; ++i) {
                exists[poolIds[_i]] = true;
            }

            nftIds = swap.nftIds;

            amount = nftIds.length;

            // iterate through nftIds and if true push to final ids array
            for (_i = 0; i < amount; ++i) {
                if (exists[nftIds[_i]]) ids.push(nftIds[_i]);
            }

            amount = poolIds.length;

            // clear exists mapping
            for (_i = 0; i < amount; ++i) {
                exists[poolIds[_i]] = false;
            }

            // if no nftIds exist in pool, delete PairSwapSpecific instance
            if (ids.length == 0) {
                delete pairList[i];

                --i;

                --length;
            
            // else set ids to swap's nftIds and set swap as PairSwapSpecifc instance
            } else {
                swap.nftIds = ids;

                pairList[i] = swap;
            }
        }
    }

}