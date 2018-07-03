module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*" // Match any network id
    }
   /*  rinkeby: {
      host: "localhost", // Connect to geth on the specified
      port: 8545,
      from: "0x48A7B0d7d41Cc6e1D04a8abbA074C02fE2293Bce", // default address to use for any transaction Truffle makes during migrations
      network_id: 4,
      gas: 4612388 // Gas limit used for deploys
    } */
  }
};
