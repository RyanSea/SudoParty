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
        IERC721 nft;

        uint _i;

        uint amount;

        address pool;

        uint length = pairList.length;

        for (uint i; i < length; ) {
            pool = address(pairList[i].pair);

            nft = pairList[i].pair.nft();

            amount = pairList[i].nftIds.length;

            // iterate through nftIds
            for (_i = 0; i < amount; ) {
                
                // if pool is not owner of id, assign index to last item and pop last item
                if (nft.ownerOf(pairList[i].nftIds[_i]) != pool) {
                    
                    pairList[i].nftIds[_i] = pairList[i].nftIds[--amount];

                    pairList[i].nftIds.pop();

                } else {
                    ++_i;
                }
            }

            // if no nftIds exist in pool, delete PairSwapSpecific instance using same method
            if (amount == 0) {

                pairList[i] = pairList[--length];

                pairList.pop();
            
            } else {
                ++i;
            }
        }
    }

}