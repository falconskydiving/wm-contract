require("@nomiclabs/hardhat-waffle");

const fs = require('fs')
const AVALANCHE_TEST_PRIVATE_KEY = fs.readFileSync(".private_key_fuji").toString().trim() || "";
const AVALANCHE_MAIN_PRIVATE_KEY = fs.readFileSync(".private_key_mainnet").toString().trim() || "";

module.exports = {
  solidity: "0.8.12",
  networks: {
    avalancheTest: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      gasPrice: 225000000000,
      chainId: 43113,
      accounts: [`0x${AVALANCHE_TEST_PRIVATE_KEY}`]
    },
    avalancheMain: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      gasPrice: 225000000000,
      chainId: 43114,
      accounts: [`0x${AVALANCHE_MAIN_PRIVATE_KEY}`]
    }
  }
};
