//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// import profiles
import "./authentication.sol";

contract Validation {

    // Events
    event requestBatchInfo(
        uint256 manufacturer_id,
        uint256 distributor_id,
        uint256 retailer_id
    );

    // Enumerations
    enum batch_status {
        Default,        // 0
        Delivered,      // 1
        Shipping,       // 2
        InStorage,      // 3
        Recalled        // 4
    }

    // Structs
    // Batch Info
    struct Batch {
        uint256 batchID;
        string DrugName;
        batch_status status;
        address manufacturerAddress;
        address distributorAddress;
        address retailerAddress;
    }

    // event to find the batch info
    // Mappings
    mapping(uint256 => Batch) public AllBatches;

    // Global Variables
    uint256 public numBatch = 0;
    address public regulator;
    Authentication auth_contract;

    // Only authority - regulator can consruct this contract
    // input address + check against the profile address
    constructor(address _a)  {
        auth_contract = Authentication(_a);
        regulator = msg.sender;
    }
    function get_regulator() public returns(address) {
        regulator = auth_contract.getRegulatorAddress();
        return regulator;
    }

    // manufacturer add batch detail
    // add the batchinfo to the map
    function addBatch(uint256 id, string memory name) public manufacturer_only returns(uint256) {
        // add batch info
        Batch memory b;
        b.batchID = id;
        b.DrugName = name;
        b.status = batch_status.InStorage;
        b.manufacturerAddress = msg.sender;

        // map the ID to AllBatches
        AllBatches[id] = b;

        // emit the status
        numBatch = numBatch + 1;
        return numBatch;

    }

    // distributor and retailer change the status
    function change_shipping(uint256 ID) public distributor_only batch_exist(ID) {
        AllBatches[ID].status = batch_status.Shipping;
        AllBatches[ID].retailerAddress = msg.sender;
    }
    function change_delivered(uint256 ID) public retailer_only batch_exist(ID) {
        AllBatches[ID].status = batch_status.Delivered;
        AllBatches[ID].distributorAddress = msg.sender;
    }

    // manufacturer recall product
    function recallBatch(uint256 id) public manufacturer_only {
        AllBatches[id].status = batch_status.Recalled;
    }

    // Calls the oracle in order to fetch related information from the database
    function showBatchInfo(uint256 id) public batch_exist(id) {
        // emit all the ID of the involved parties
        Batch storage b = AllBatches[id];

        uint256 m = auth_contract.getAccountID(b.manufacturerAddress);
        uint256 d = auth_contract.getAccountID(b.distributorAddress);
        uint256 r = auth_contract.getAccountID(b.retailerAddress);

        emit requestBatchInfo(m, d, r);
    }

    // Caleld by the oracle in order to show information on chain
    function showBatchInfoCallback(string memory MANUFACTURER, string memory DISTRIBUTOR, string memory RETAILER) public pure
            returns (string memory m, string memory d, string memory r) {
        m = MANUFACTURER;    // -:- Name : _____ -:- Address : _____ -:-
        d = DISTRIBUTOR;     // -:- Name : _____ -:- Address : _____ -:-
        r = RETAILER;        // -:- Name : _____ -:- Address : _____ -:-
    }

    // Modifiers
    // the msg.sender address is the regulator
    modifier isregulator {
        require(msg.sender == regulator, "Must be regulator");
        _;
    }

    // the msg.sender address is from a registered manufacturer
    modifier manufacturer_only {
        require(auth_contract.isManufacturer(msg.sender) == true, "Must be manufacturer");
        _;
    }

    // the msg.sender address is from a registered distributor
    modifier distributor_only {
        require(auth_contract.isDistributor(msg.sender) == true, "Must be distributor");
        _;
    }

    // the msg.sender address is from a registered retailer
    modifier retailer_only {
        require(auth_contract.isRetailer(msg.sender) == true, "Must be retailer");
        _;
    }

    modifier batch_exist(uint256 id) {
        require(
            AllBatches[id].batchID != 0,
            "This batch id does not exist. Please input a valid id."
        );
        _;
    }

}