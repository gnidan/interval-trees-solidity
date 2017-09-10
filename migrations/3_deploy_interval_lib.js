var IntervalLib = artifacts.require("./intervals/IntervalLib.sol");

module.exports = function(deployer) {
  deployer.deploy(IntervalLib);
}
