var IntervalTree = artifacts.require("./IntervalTree.sol");
var IntervalTreeLib = artifacts.require("./IntervalTreeLib.sol");

var GroveLib = artifacts.require("./vendor/grove/GroveLib.sol");

module.exports = function(deployer) {
  deployer.link(GroveLib, IntervalTreeLib);
  deployer.deploy(IntervalTreeLib);
  deployer.link(IntervalTreeLib, IntervalTree);
  deployer.link(GroveLib, IntervalTree);
  deployer.deploy(IntervalTree);
}
