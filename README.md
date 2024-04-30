# DRUG SUPPLY CHAIN

REQUIREMENTS:
NPM
Node v16
Ganache

Please install npm first.

We are using remix IDE to run and compile contracts.
All smart contracts are in the smart_contracts folder.

Navigate to the respective folder and install all dependencies using the below command:

`npm install`

To run the oracle file use:

`node oracle.js`

Instructions to make sure the setup works:

- Make sure the ABIs in the local folder match the contract ABIs in remix
- run the setup.sh file to ensure all relevant libraries are installed

Instructions for local setup:

1. Ganache (same as tutorial four)

- open a ganache server and pretty much leave it as default
- add the network to MetaMask
- import the accounts that will be interacting with the contracts on metamask

2.  Remix

- compile and deploy the smart contracts using the account that will be the regulator
- add authentication contract’s address in constructor of validation contract while deploying

3.  Oracle

- copy paste the smart contract addresses from remix into their respective variables
- copy paste the regulator private key from ganache into its variable
- run the oracle using node oracle.js
