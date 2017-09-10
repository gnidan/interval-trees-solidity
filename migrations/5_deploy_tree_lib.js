var GroveLib = artifacts.require("./vendor/grove/GroveLib.sol");

var TreeLib = artifacts.require("./intervals/TreeLib.sol");
var ListLib = artifacts.require("./intervals/ListLib.sol");
var IntervalLib = artifacts.require("./intervals/IntervalLib.sol");


module.exports = function(deployer) {
  deployer.link(GroveLib, TreeLib);
  deployer.link(IntervalLib, TreeLib);
  deployer.link(ListLib, TreeLib);

  deployer.deploy(TreeLib);
}
