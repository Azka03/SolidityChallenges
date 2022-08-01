import * as dotenv from "dotenv"; //Dotenv is a zero-dependency module that loads environment variables from a .env file into process.env.
//process.env - global variable injected by node at runtime
import { HardhatUserConfig } from "hardhat/config";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "solidity-coverage"; 

dotenv.config();
/* This loads the variables in your .env file to `process.env` */
const { PRIVATEKEY, RINKEBY_URL } = process.env;
const config: HardhatUserConfig = {
  solidity: {
    compilers: [ //list of compiler configurations
      {
        version: "0.8.9", //multiple versions can be used 
        settings: {
          optimizer: {
            enabled: true, //by default it is disabled
            runs: 200,  //size of code is optimized
          },
        },
      },
    ],
  },

  //Optional object - default => hardhat
  networks: { //JSON RPC(Remote Procedure Calls)
    // allows for notifications (data sent to the server that does not require a response) and for
    // multiple calls to be sent to the server which may be answered asynchronously.
    //- (Connect/Intereact to an external node)
    // ropsten: {
    //   url: "https://mainnet.infura.io/v3/f9cdbdd7dec24ed482ddf1f178d103fc", //URL of the node 
    //   // accounts: ['e87ee6e7014230f70de1d9d50185af2693fd372d9462f4c070b6b0d074de6d34'], //account hardhat uses
    //  accounts: ['41e313c8a5211c6ba7001847ebabd38c59edd04beed6be5dd4db1e91c1e21dc8']
    // },
    rinkeby: {
      url: `${RINKEBY_URL}`,
      accounts: [`0x${PRIVATEKEY}`]
    }
  },
  // etherscan: {
  //   // Your API key for Etherscan
  //   // Obtain one at https://etherscan.io/
  //   apiKey: process.env.ETHERSCAN_API, //API requried for verification of our contract 
  // },
  mocha: { //test runner
    timeout: 200000000, //time limit to perform a test otherwise it fails
  },
};
export default config;