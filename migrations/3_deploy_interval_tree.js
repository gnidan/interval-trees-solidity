var IntervalTree = artifacts.require("./IntervalTree.sol");
var IntervalTreeLib = artifacts.require("./IntervalTreeLib.sol");
var IntervalListLib = artifacts.require("./IntervalListLib.sol");
var IntervalLib = artifacts.require("./IntervalLib.sol");

var GroveLib = artifacts.require("./vendor/grove/GroveLib.sol");

module.exports = function(deployer) {
  deployer.link(GroveLib, [IntervalListLib, IntervalTreeLib, IntervalTree]);

  deployer.deploy(IntervalLib);
  deployer.link(IntervalLib, [IntervalListLib, IntervalTreeLib, IntervalTree]);

  deployer.deploy(IntervalListLib);
  deployer.link(IntervalListLib, [IntervalTreeLib, IntervalTree]);

  deployer.deploy(IntervalTreeLib);
  deployer.link(IntervalTreeLib, IntervalTree);

  deployer.deploy(IntervalTree);
}
