import { HardhatUserConfig } from "hardhat/config";
import 'solidity-coverage'
import "@openzeppelin/hardhat-upgrades";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-gas-reporter";

const REPORT_GAS = true

/**
 * gasPriceApi
 * Ethereum  https://api.etherscan.io/api?module=proxy&action=eth_gasPrice
 * Polygon   https://api.polygonscan.com/api?module=proxy&action=eth_gasPrice
 * 
 */

const config: HardhatUserConfig = {
  
  defaultNetwork: "localhost",
  networks: {
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com/",
      accounts: ["1e028a66574a999b6e4facc223fd5e823230bb034a36f2baf82effae46146550"],
      chainId: 80001,

    },
    hardhat: {
      chainId: 1337,
      forking: {
        url: "https://polygon-mainnet.g.alchemy.com/v2/IbuqogQ3TP4Llb18Ty5ltMmRO7SpeZ7z",
        blockNumber: 43659594
      }
    },
    localhost:{
      url: "http://127.0.0.1:8545",
    },
    polygon: {
      url: "https://polygon-mainnet.g.alchemy.com/v2/IbuqogQ3TP4Llb18Ty5ltMmRO7SpeZ7z",
      accounts: ["fa043c79d64209c8de6746871124ab3066acb9394813d8526f656ed9902b012f"],
      chainId: 137,
      gasPrice: 200000000000,
      gas: 4000000,
    },
    goerli: {
      url: "https://eth-goerli.g.alchemy.com/v2/q04sQKbbsntbXFOad8DCFZ_5kR8jEJ4x",
      accounts: ["1ae329dcfefe371422a9f3dcddfb742e6848525afe02fa2c0cae71a42788abf4"],
      chainId: 5,
      gasPrice: 200000000000,
      gas: 4000000,

    },
    sepolia: {
      url: "https://sepolia.infura.io/v3/7307908c50f44d578fd7470e6df7921e",
      accounts: ["9fd4abb4a4e78804ae4b40fbab6d53355fffc701da2dbd9be567ce52bca22fca","ee0832ebea198e742900d6c727413cef4b96edd053e5480b336809e06939005a"]
    }
  },
 
  solidity: {
    version: '0.8.9',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    },
    
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  gasReporter: {
    enabled: true,
    currency: "USDT",
    outputFile: "gas-report.txt",
    noColors: true,
    showMethodSig: true,
    token:"ETH",
    gasPriceApi:"https://api.polygonscan.com/api?module=proxy&action=eth_gasPrice",
    coinmarketcap: "5714a2b5-1312-4287-8e03-458830baaf31",
    url:"http://127.0.0.1:8545"
  },
  mocha: {
    timeout: 40000,
    reporter: 'eth-gas-reporter',

    reporterOptions: {
      excludeContracts: ['Lock'],
    },
  },
  etherscan: {
    // apiKey:"INS6152CQFPE3EJZ7P7QF4FHGVIMCBPG9X"
    apiKey:"YXWQB4J9E37B211I6TT4FU6E33PGARXXYV", //sepolia
    
  }
  
  
   
}

export default config;
