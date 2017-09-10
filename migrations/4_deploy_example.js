var GroveLib = artifacts.require("./vendor/grove/GroveLib.sol");

var TreeLib = artifacts.require("./intervals/TreeLib.sol");
var ListLib = artifacts.require("./intervals/ListLib.sol");
var IntervalLib = artifacts.require("./intervals/IntervalLib.sol");

var Example = artifacts.require("./Example.sol");

module.exports = function(deployer) {
  deployer.link(GroveLib, Example);
  deployer.link(IntervalLib, Example);
  deployer.link(ListLib, Example);
  deployer.link(TreeLib, Example);

  deployer.deploy(Example);
}
