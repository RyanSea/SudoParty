// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISudoPartyManager {
    enum ProposalType {
        sell,
        set_consensus,
        withdraw
    }

    function stake(address sender, uint amount) external;

    function unstake(address sender, uint amount) external;

    function createProposal(address sender, ProposalType _type, uint amount, address withdrawal) external;

    function vote(address sender, uint id, bool yes) external;

    function finalize(uint id) external;

    function claim(address sender) external;

    function withdraw(address sender, address withdrawal) external;
}