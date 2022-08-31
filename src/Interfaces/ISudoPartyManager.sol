// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISudoPartyManager {
    enum ProposalType {
        sell,
        set_consensus,
        withdraw
    }

    function stake(uint amount) external;

    function unstake(uint amount) external;

    function createProposal(ProposalType _type, uint amount, address withdrawal) external;

    function vote(uint id, bool yes) external;

    function finalize(uint id) external;

    function claim() external;

    function withdraw(address withdrawal) external;
}