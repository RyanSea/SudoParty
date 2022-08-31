# SudoParty!
Protocol to group buy, own, and sell NFT's on Sudoswap
Currently supports buying/selling a single, specific NFT

## SudoPartyHub.sol
Router contract. Used to create SudoParties via IPartyFactory.sol & IManagerFactory.sol

## SudoParty
Every SudoParty consists of a SudoParty.sol contract, which is used to group-buy a token & SudoPartyManager.sol which is for governance of a successfully purchased NFT. These are also the unstaked & staked NFT fractional tokens, respectively.

### SudoParty.sol
Main protocol contract. Every group-buying attempt is a 'SudoParty', and the params for contract creation include whitelist array (which can be empty), deadline for the SudoParty to make a successful purchase before funds can be withdrawn, and consenus (0-100) to pass a yes vote once the NFT is purchased (this can be changed with a proposal in SudoPartyManager.sol).
Functions include the ability to open the party if whitelisted, add to the whitelist, contribute, and attempt to buy the NFT. If the token purchase is successful, tokens are minted (wei token for wei spent) & claimable by the contributors. 

### SudoPartyManager.sol
Governance contract. This is where NFT fraction tokens can be staked so that proposals can be created, and voted on. Proposal types are listing the NFT on sudoswap (param is price), set a new consensus (param is conensus percentage), and withdraw (param is address). 
The staked tokens are non-transferabl &Proceeds from the sale are claimable to holders.

## Factories
### PartyFactory.sol
Creates SudoParties
### ManagerFactory.sol 
Creaetes SudoParty Managers