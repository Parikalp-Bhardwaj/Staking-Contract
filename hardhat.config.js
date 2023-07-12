require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
  networks: {
    localhost: {
      chainId: 15,
      url: "http://127.0.0.1:8546"
    },
  },
  paths: {
    artifacts: "./client/src/artifacts",
  },
};
