// ExpressJS Setup
const express = require('express');
const app = express();
var bodyParser = require('body-parser');

// Constants
const PORT = 8800;
const HOST = "0.0.0.0";

 // Hyperledger Bridge
const { FileSystemWallet, Gateway } = require('fabric-network');
const fs = require('fs');
const path = require('path');
const ccpPath = path.resolve(__dirname, '..','..','basic-network','connection.json');
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);
const walletPath = path.join(process.cwd(), 'wallet');
const wallet = new FileSystemWallet(walletPath);


app.use(express.static(path.join(__dirname, 'views')));
app.use(bodyParser.urlencoded({ extended: false }));

// Index page
app.get('/', function (req, res) {
    res.sendFile(__dirname + '/views/index.html');
});

app.get('/get', async function (req, res) {

    const id = req.query.id

    const userExists = await wallet.exists('user1');
    if (!userExists) {
        console.log('An identity for the user "user1" does not exist in the wallet');
        console.log('Run the registerUser.js application before retrying');
        return;
    }
    const gateway = new Gateway();
    await gateway.connect(ccp, { wallet, identity: 'user1', discovery: { enabled: false } });
    const network = await gateway.getNetwork('mychannel');
    const contract = network.getContract('myfirstcc');
    const result = await contract.evaluateTransaction("get",id);


    console.log(`result:${result}`);
    // var obj = JSON.parse(result)
    // console.log(`result:${obj}`);
    // res.json(obj)


    res.status(200).send(result)
});

app.post('/set', async function (req, res) {

    const id = req.body.id;
    const setdata = req.body.setdata;

    const userExists = await wallet.exists('user1');
    if (!userExists) {
        console.log('An identity for the user "user1" does not exist in the wallet');
        console.log('Run the registerUser.js application before retrying');
        return;
    }
    const gateway = new Gateway();
    await gateway.connect(ccp, { wallet, identity: 'user1', discovery: { enabled: false } });
    const network = await gateway.getNetwork('mychannel');
    const contract = network.getContract('myfirstcc');
    const result = await contract.submitTransaction("set",id,setdata);


    console.log(`result:${result}`);

    res.status(200).send(result)
});

app.get('/getAll', async function (req, res) {
    const userExists = await wallet.exists('user1');
    if (!userExists) {
        console.log('An identity for the user "user1" does not exist in the wallet');
        console.log('Run the registerUser.js application before retrying');
        return;
    }
    const gateway = new Gateway();
    await gateway.connect(ccp, { wallet, identity: 'user1', discovery: { enabled: false } });
    const network = await gateway.getNetwork('mychannel');
    const contract = network.getContract('myfirstcc');
    const result = await contract.evaluateTransaction("getAllKeys");

    console.log(`result:${result}`);
    res.status(200).send(result)
});

app.get('/getHistory', async function (req, res) {

    const id = req.query.id

    const userExists = await wallet.exists('user1');
    if (!userExists) {
        console.log('An identity for the user "user1" does not exist in the wallet');
        console.log('Run the registerUser.js application before retrying');
        return;
    }
    const gateway = new Gateway();
    await gateway.connect(ccp, { wallet, identity: 'user1', discovery: { enabled: false } });
    const network = await gateway.getNetwork('mychannel');
    const contract = network.getContract('myfirstcc');
    const result = await contract.evaluateTransaction("getHistoryForKey",id);


    console.log(`result:${result}`);
    res.status(200).send(result)
});

// server start
app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
