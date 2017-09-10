var GroveLib = artifacts.require("./vendor/grove/GroveLib.sol");

var ListLib = artifacts.require("./intervals/ListLib.sol");
var IntervalLib = artifacts.require("./intervals/IntervalLib.sol");


module.exports = function(deployer) {
  deployer.link(GroveLib, ListLib);
  deployer.link(IntervalLib, ListLib);

  deployer.deploy(ListLib);
}
