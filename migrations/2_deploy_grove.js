var GroveLib = artifacts.require("./vendor/grove/GroveLib.sol");
var Grove = artifacts.require("./vendor/grove/Grove.sol");

module.exports = function(deployer) {
  deployer.deploy(GroveLib);
  deployer.link(GroveLib, Grove);
  deployer.deploy(Grove);
}
