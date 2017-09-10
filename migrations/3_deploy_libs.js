var GroveLib = artifacts.require("./vendor/grove/GroveLib.sol");

var TreeLib = artifacts.require("./intervals/TreeLib.sol");
var ListLib = artifacts.require("./intervals/ListLib.sol");
var IntervalLib = artifacts.require("./intervals/IntervalLib.sol");


module.exports = function(deployer) {
  deployer.link(GroveLib, [ListLib, TreeLib]);

  deployer.deploy(IntervalLib);
  deployer.link(IntervalLib, [ListLib, TreeLib]);

  deployer.deploy(ListLib);
  deployer.link(ListLib, TreeLib);

  deployer.deploy(TreeLib);
}
