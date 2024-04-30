// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Contract to agree on the Auth
contract Authentication {

    // Events
    event AccountCreated(string accountName, string streetAddress, string contactNumber, uint256 incrementalId);

    // Enumerations
    enum AccountType {
        Default,        // 0
        Manufacturer,   // 1
        Distributor,    // 2
        Retailer,       // 3
        Oracle          // 4
    }

    // Mappings
    mapping(address => uint256) public accounts;
    mapping(address => AccountType) public atype;

    // Global Variables
    address public regulator; //Manager account
    uint public numAccounts = 0;
    uint256 incrementalId = 0;

    // Constructor
    constructor ()  {
        regulator = msg.sender; // Set the contract initiator as the regulator
    }

    // Add an account to the blockchain
    function addAccount(address accountAddress,
                        AccountType accountType,
                        string memory accountName,
                        string memory contactNumber,
                        string memory streetAddress)
                        public restricted returns (uint) {

        // Store local contract information
        accounts[accountAddress] = incrementalId;
        atype[accountAddress] = accountType;

        // Call the event for the roacle to insert information into the database
        emit AccountCreated(accountName, streetAddress, contactNumber, incrementalId);

        // Increment counters
        incrementalId++;
        numAccounts ++;
        return numAccounts;
    }

    function getRegulatorAddress() public view returns (address)
    {
        return regulator;
    }

    function getAccountID(address a) public view returns (uint256) {
        return accounts[a];
    }

    modifier restricted() {
        require (msg.sender == regulator, "Can only be executed by the regulator");
        _;
    }

    // Added by Caspar
    function isManufacturer(address accountAddress) public view returns (bool) {
        if (atype[accountAddress] == AccountType.Manufacturer) {
            return true;
        }
        else {
            return false;
        }
    }

    // Added by Caspar
    function isRetailer(address accountAddress) public view  returns (bool) {
        if (atype[accountAddress] == AccountType.Retailer) {
            return true;
        }
        else {
            return false;
        }
    }

    // Added by Caspar
    function isDistributor(address accountAddress) public view returns (bool) {
        if (atype[accountAddress] == AccountType.Distributor) {
            return true;
        }
        else {
            return false;
        }
    }


}