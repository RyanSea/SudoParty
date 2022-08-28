# SudoParty!
Protocol to group buy, own, and sell NFT's on Sudoswap
Currently supports buying/selling a single, specific NFT

## SudoPartyHub.sol
Router contract. Currently unused contract shown as an example of how SudoParties will be made and interfaced with. Pool address, NFT address, and NFT ID are cast as a byte and mapped to the address of the SudoParty. Pool, NFT, and ID are called as the first 3 params for every function to make calls to a given SudoParty. This was just a PoC and will change as the protocol enables buying multiple NFT's from multiple pools.

## SudoParty.sol
Main protocol contract. Every group-buying attempt is a 'SudoParty', and the params for contract creation include whitelist array (which can be empty), deadline for the SudoParty to make a successful purchase before funds can be withdrawn, and consenus (0-100) to pass a yes vote once the NFT is purchased (this can be changed with a proposal in SudoPartyManager.sol).
Functions include the ability to open the party if whitelisted, add to the whitelist, contribute, and attempt to buy the NFT. If the token purchase is successful, tokens are minted (wei token for wei spent) & claimable by the contributors. 

## SudoPartyManager.sol
Governance contract. This is where NFT fraction tokens can be staked so that proposals can be created, and voted on. Proposal types are listing the NFT on sudoswap (param is price), set a new consensus (param is conensus percentage), and withdraw (param is address). 
The staked tokens are non-transferable (forgot to do this for the hackathon, but it's a super simple process consisting of a few lines of code).
Proceeds from the sale are claimable to holders.