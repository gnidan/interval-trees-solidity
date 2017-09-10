var GroveLib = artifacts.require("./vendor/grove/GroveLib.sol");

var TreeLib = artifacts.require("./intervals/TreeLib.sol");
var ListLib = artifacts.require("./intervals/ListLib.sol");
var IntervalLib = artifacts.require("./intervals/IntervalLib.sol");

var IntervalTree = artifacts.require("./IntervalTree.sol");

module.exports = function(deployer) {
  deployer.link(GroveLib, [ListLib, TreeLib, IntervalTree]);

  deployer.deploy(IntervalLib);
  deployer.link(IntervalLib, [ListLib, TreeLib, IntervalTree]);

  deployer.deploy(ListLib);
  deployer.link(ListLib, [TreeLib, IntervalTree]);

  deployer.deploy(TreeLib);
  deployer.link(TreeLib, IntervalTree);

  deployer.deploy(IntervalTree);
}
