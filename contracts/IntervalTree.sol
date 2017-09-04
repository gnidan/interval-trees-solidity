pragma solidity ^0.4.15;

import "./vendor/grove/GroveLib.sol";

import "./IntervalTreeLib.sol";

contract IntervalTree {
  IntervalTreeLib.Tree tree;

  using IntervalTreeLib for IntervalTreeLib.Tree;

  function IntervalTree() {
  }

  function addInterval(uint begin, uint end, bytes32 data) {
    tree.addInterval(begin, end, data);
  }

  function numIntervals() constant returns (uint) {
    return tree.numIntervals;
  }

  function intervalsAt(uint point) constant returns (uint) {
    return tree.intervalsAt(point);
  }

  function intervalAt(uint point, uint offset)
    constant
    returns (uint begin, uint end, bytes32 data)
  {
    return tree.intervalAt(point, offset);
  }

}
