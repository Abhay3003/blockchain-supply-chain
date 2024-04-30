// Oracle for Supply Chain system

// Required Packages
const Web3 = require('web3');
const MongoClient = require('mongodb').MongoClient;

// Database
const dbURI = 'mongodb+srv://comp6452:comp6452@sc2_blockchain.qvu0tvy.mongodb.net/?retryWrites=true&w=majority';

(async () => {
    // Web3 Provider Setup
    const web3Provider = new Web3.providers.WebsocketProvider("ws://localhost:7545");
    const web3 = new Web3(web3Provider);

    const account = web3.eth.accounts.wallet.add("0x" + "bb941fd22e61a250c73bff7a47b6ba7e6336c702683e9f9833949e038a111dc9");

    // Smart Contract Setup
    addressAuth = "0x1c748305D66bFd5D680EbbfC4D665C8e5fD4a1eD"
    addressVal = "0xeB0C29417371871BFf203626A4b66E721F354896"

    const authenticationABI = require('./contract_abis/authentication_abi.json');
    const validationABI = require('./contract_abis/validation_abi.json');

    const myAuthContract = new web3.eth.Contract(authenticationABI, addressAuth);
    const myValContract = new web3.eth.Contract(validationABI, addressVal);

    const gasPriceTemp = await web3.eth.getGasPrice();
    const gasTemp = await getGas(myValContract, account, "m_string", "d_string", "r_string");
    const gasEstimates = [gasPriceTemp, gasTemp];

    // Starts the Contract Listener
    console.log("Listening on Contract Addresses : Auth = " + addressAuth + " : Val = " + addressVal);
    listener(myAuthContract, myValContract, account, gasEstimates);
})();

// Listener function for both smart contracts
// INPUT : Contract myAuthContract, Contract myValContract, Account account, Array gasEstimates
function listener(myAuthContract, myValContract, account, gasEstimates) {

    // Listening function that activates when the AccountCreated event is called in the respective Auth contract
    // INPUT : string accountName, string streetAddress, string contactNumber, uint256 incrementalId
    const acountCreatedHandler = myAuthContract.events.AccountCreated((error, event) => {
        if (error) throw error;

        console.log("Event Called : AccountCreated");

        // Interactions with the database
        MongoClient.connect(dbURI, function(err, client) {
            if (err) throw err;
            let db = client.db("usersDB");
            let myobj = {
                id: event.returnValues.incrementalId,
                name: event.returnValues.accountName,
                number: event.returnValues.contactNumber,
                address: event.returnValues.streetAddress
            };

            // If a document already exists with the corresponding id, it is deleted
            db.collection("users").find({ id: myobj.id }).toArray((err, result) => {
                if (err) throw err;
                if (result.length > 0) {
                    db.collection("users").deleteOne({ id: myobj.id }, function(err, obj) {
                        if (err) throw err;
                        console.log("Event Update : Account Created\n  - Pre-existing values found and deleted")
                    });
                }
            });

            // Adds a document to represent the company in the database
            db.collection("users").insertOne(myobj, function(err, result) {
                if (err) throw err;
                console.log("Event Completed : AccountCreated");
                console.log("  Result:\n    id: " + myobj.id);
                client.close;
            });
        });
    });

    // Listening function that activates when the requestBatchInfo event is called in the respective validation contract
    // INPUT : uint256 manufacturer_id, uint256 distributor_id, uint256 retailer_id
    // OUTPUT : Sends a request to the validation contract to callshowBatchInfoCallback which will show the information stored in the database
    const showBatchInfo = myValContract.events.requestBatchInfo((error, event) => {
        if (error) throw error;

        console.log("Event Called : requestBatchInfo");

        // Sets return information in case a document doesn't exist
        let m_string = "Information not available";
        let d_string = "Information not available";
        let r_string = "Information not available";
    
        // Retrieves event information
        let m_id = event.returnValues.manufacturer_id;
        let d_id = event.returnValues.distributor_id;
        let r_id = event.returnValues.retailer_id;
    
        // Connects to the database
        MongoClient.connect(dbURI, (err, client) => {
            if (err) throw err;
            let db = client.db("usersDB");
            let query = { $or: [{ id: m_id }, { id: d_id }, { id: r_id }] };

            // Searches the database for corresponding documents and formats into strings
            // If the document doesn't exist, nothing happens
            db.collection("users").find(query).toArray((err, result) => {
                if (err) throw err;
                for (let i in result) {
                    if (result[i].id == m_id) {
                        m_string = userToString(result[i]);
                    } else if (result[i].id == d_id) {
                        d_string = userToString(result[i]);
                    } else if (result[i].id == r_id) {
                        r_string = userToString(result[i]);
                    }
                }
                client.close;

                // Sends the information back to the smart contract
                try {
                    myValContract.methods.showBatchInfoCallback(m_string, d_string, r_string).send({
                        from: account.address,
                        gasPrice: gasEstimates[0],
                        gas: gasEstimates[1]
                    }).then(function(receipt) {
                        console.log("Event Completed : requestBatchInfo");
                        console.log("  Results:\n    " + m_string + "\n    " + d_string + "\n    " + r_string);
                        return receipt;
                    }).catch((err) => {
                        console.error(err);
                    });
                } catch (e) { console.log(e) }
            });
        });
    });

    /*const FindBatchStatus = myValContract.events.FindBatchStatus((error, event) => {
        if (error) {
            throw error;
        }

        console.log("Event Called : FindBatchStatus");
        console.log(event.returnValues);
    });*/
}

// Estimates the gas for showBatchInfoCallback
async function getGas(myValContract, account, m_string, d_string, r_string) {
    let temp = await myValContract.methods.showBatchInfoCallback(m_string, d_string, r_string).estimateGas({ from: account.address })
    return Math.ceil(1.2 * temp);
}

// Formats the database information into a string format
function userToString(data) {
    return "-:- Name: " + data.name + " -:- Contact Number: " + data.number + " -:- Address: " + data.address + " -:-";
}

