pragma solidity ^0.4.15;

import "./intervals/TreeLib.sol";

contract IntervalTree {
  TreeLib.Tree tree;

  using TreeLib for TreeLib.Tree;

  function IntervalTree() {
  }

  function addInterval(uint begin, uint end, bytes32 data) {
    tree.addInterval(begin, end, data);
  }

  function numIntervals() constant returns (uint) {
    return tree.numIntervals;
  }

  function intervalsAt(uint point) constant returns (uint) {
    return tree.search(point).length;
  }

  function intervalAt(uint point, uint offset)
    constant
    returns (uint begin, uint end, bytes32 data)
  {
    var results = tree.search(point);

    require(offset < results.length);

    return tree.getInterval(results[offset]);
  }

}
