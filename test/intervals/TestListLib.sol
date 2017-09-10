pragma solidity ^0.4.15;

import "truffle/Assert.sol";

import "../../contracts/intervals/ListLib.sol";

contract TestListLib {
  using ListLib for ListLib.List;

  ListLib.List intervals;

  function test0_create() {
    intervals = ListLib.createNew();
    Assert.equal(intervals.length, 0, "Initial list should be empty");
  }

  function test1_addingFirst() {
    intervals.add(3, 7, 1);

    Assert.equal(intervals.length, 1, "Added intervals should be counted");
    Assert.equal(intervals.center, 5, "Center should update on first add");
  }

  function test2_addingSecond() {
    var oldCenter = intervals.center;
    var oldLowest = intervals.lowestBegin;
    var oldHighest = intervals.highestEnd;

    intervals.add(1, 6, 2);

    Assert.equal(intervals.length, 2, "Added intervals should be counted");
    Assert.equal(intervals.center, oldCenter, "List center should not change");
    Assert.notEqual(intervals.lowestBegin, oldLowest, "Lowest beginning interval should update");
    Assert.equal(intervals.highestEnd, oldHighest, "Highest ending interval should not update");
  }
}
