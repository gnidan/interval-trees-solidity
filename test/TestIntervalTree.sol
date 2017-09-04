pragma solidity ^0.4.15;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

import "../contracts/IntervalTree.sol";

contract TestIntervalTree {
  function testAddInterval() {
    IntervalTree tree = IntervalTree(DeployedAddresses.IntervalTree());

    tree.addInterval(1, 9, 0xDEADBEEF);
    Assert.equal(tree.numIntervals(), 1, "There should be 1 interval");

    Assert.equal(tree.intervalsAt(5), 1, "Point search should find 1 interval");
    Assert.equal(tree.intervalsAt(0), 0, "Strictly below interval should find 0 intervals");
    Assert.equal(tree.intervalsAt(9), 0, "Upper boundary exact match should find 0 intervals");

    tree.addInterval(3, 4, 0xF00DF00D);
    Assert.equal(tree.numIntervals(), 2, "There should be 2 intervals");

    Assert.equal(tree.intervalsAt(5), 1, "Point search should find 1 interval");
    Assert.equal(tree.intervalsAt(3), 2, "Common point should find 2 intervals");
    Assert.equal(tree.intervalsAt(4), 1, "Upper-bound on only 1 should find 1 match");

  }
}
