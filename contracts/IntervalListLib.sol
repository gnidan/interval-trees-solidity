pragma solidity ^0.4.15;

import "./vendor/grove/GroveLib.sol";

import "./IntervalLib.sol";

library IntervalListLib {
  using GroveLib for GroveLib.Index;
  using IntervalLib for IntervalLib.Interval;

  struct List {
    // maps item ID to items
    mapping (uint => IntervalLib.Interval) items;

    GroveLib.Index beginIndex;
    GroveLib.Index endIndex;
    bytes32 lowestBegin;
    bytes32 highestEnd;
  }

  function createNew(uint id)
    internal
    returns (List)
  {
    return List({
      lowestBegin: 0x0,
      highestEnd: 0x0,
      beginIndex: GroveLib.Index(sha3(this, bytes32(id * 2))),
      endIndex: GroveLib.Index(sha3(this, bytes32(id * 2 + 1)))
    });
  }

//   function first(List storage list)
//     constant
//     returns (bytes32 itemData)
//   {


//   }

//   function next(List storage list, bytes32 itemIndex)
//     constant
//     returns (bytes32)
//   {
//     return list.index.getNextNode(itemIndex);
//   }

//   function previous(List storage list, bytes32 itemIndex)
//     constant
//     returns (bytes32)
//   {
//     return list.index.getPreviousNode(itemIndex);
//   }

}

