pragma solidity ^0.4.15;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

import "../contracts/IntervalTree.sol";

contract TestIntervalTree {
  function testIntervals() {
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

    uint begin1;
    uint end1;
    bytes32 data1;

    uint begin2;
    uint end2;
    bytes32 data2;

    (begin1, end1, data1) = tree.intervalAt(3, 0);
    (begin2, end2, data2) = tree.intervalAt(3, 1);

    Assert.equal(
      begin1 == 1 && end1 == 9 && data1 == 0xDEADBEEF ||
      begin2 == 1 && end2 == 9 && data2 == 0xDEADBEEF,
      true,
      "Should find first interval"
    );
    Assert.equal(
      begin1 == 3 && end1 == 4 && data1 == 0xF00DF00D ||
      begin2 == 3 && end2 == 4 && data2 == 0xF00DF00D,
      true,
      "Should find second interval"
    );
  }
}
