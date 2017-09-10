module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 9545,
      network_id: "*" // Match any network id
    },
    main: {
      host: "localhost",
      port: 8545,
      network_id: "1"
    },
  }
};
