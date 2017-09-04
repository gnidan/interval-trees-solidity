pragma solidity ^0.4.15;

import "./vendor/grove/GroveLib.sol";

library IntervalTreeLib {
  using GroveLib for GroveLib.Index;

  struct Tree {
    // global table of intervals
    mapping (uint => Interval) intervals;
    uint numIntervals;

    // tree nodes
    mapping (uint => Node) nodes;
    uint numNodes;

    // pointer to root of tree
    uint rootNode;
  }

  struct Node {
    uint center;
    uint nodeBefore;
    uint nodeAfter;
    uint count;
    GroveLib.Index beginIndex;
    GroveLib.Index endIndex;

    // references to boundary intervals (GroveLib.Index node IDs)
    bytes32 lowestBeginIndexNode;
    bytes32 highestEndIndexNode;
  }

  struct Interval {
    uint begin;
    uint end;
    bytes32 data;
  }

  function addInterval(Tree storage tree, uint begin, uint end, bytes32 data) internal {
    uint intervalID = _createInterval(tree, begin, end, data);

    if (tree.rootNode == 0) {
      var nodeID = _createNode(tree, begin, end);
      tree.rootNode = nodeID;

      var node = tree.nodes[nodeID];
      _addIntervalToNode(node, begin, end, intervalID);

      return;
    }

    uint curID = tree.rootNode;
    var curNode = tree.nodes[curID];

    bool found = false;

    while (!found) {
      bool updateBefore = false;

      if (end <= curNode.center) {
	curID = curNode.nodeBefore;
	updateBefore = true;
      } else if (begin > curNode.center) {
	curID = curNode.nodeAfter;
      } else {
	found = true;
	break;
      }

      if (curID == 0) {
	curID = _createNode(tree, begin, end);

	if (updateBefore) {
	  curNode.nodeBefore = curID;
	} else {
	  curNode.nodeAfter = curID;
	}
      }

      curNode = tree.nodes[curID];
    }

    _addIntervalToNode(curNode, begin, end, intervalID);
  }

  /*
   * insert helpers
   */
  function _createInterval(Tree storage tree, uint begin, uint end, bytes32 data)
    internal
    returns (uint intervalID)
  {
    intervalID = ++tree.numIntervals;

    tree.intervals[intervalID] = Interval({
      begin: begin,
      end: end,
      data: data
    });
  }

  function _createNode(Tree storage tree, uint begin, uint end) returns (uint nodeID) {
    nodeID = ++tree.numNodes;
    tree.nodes[nodeID] = Node({
      center: begin + (end - begin) / 2,
      nodeBefore: 0,
      nodeAfter: 0,
      count: 0,
      lowestBeginIndexNode: 0x0,
      highestEndIndexNode: 0x0,
      beginIndex: GroveLib.Index(sha3(this, bytes32(nodeID * 2))),
      endIndex: GroveLib.Index(sha3(this, bytes32(nodeID * 2 + 1)))
    });
  }

  function _addIntervalToNode(Node storage node, uint begin, uint end, uint intervalID) {
    var _intervalID = bytes32(intervalID);
    var _begin = getBeginIndexKey(begin);
    var _end = getEndIndexKey(end);

    node.beginIndex.insert(_intervalID, _begin);
    node.endIndex.insert(_intervalID, _end);
    node.count++;

    if (node.count == 1) {
      node.lowestBeginIndexNode = node.beginIndex.root;
      node.highestEndIndexNode = node.endIndex.root;

      return;
    }

    var newLowest = node.beginIndex.getPreviousNode(node.lowestBeginIndexNode);
    if (newLowest != 0x0) {
      node.lowestBeginIndexNode = newLowest;
    }

    var newHighest = node.endIndex.getNextNode(node.highestEndIndexNode);
    if (newHighest != 0x0) {
      node.highestEndIndexNode = newHighest;
    }
  }

  function _searchNode(Node storage node, uint point)
    constant
    internal
    returns (uint[] memory intervalIDs, bool searchLower, bool searchHigher)
  {
    uint[] memory _intervalIDs = new uint[](node.count);
    uint num = 0;

    bytes32 cur;

    if (point < node.center) {
      searchLower = true;
      searchHigher = false;

      cur = node.lowestBeginIndexNode;
      while (cur != 0x0) {
	uint begin = _begin(node, cur);
	if (begin > point) {
	  break;
	}

	_intervalIDs[num] = uint(node.beginIndex.getNodeId(cur));
	num++;

	cur = _next(node, cur);
      }
    }

    if (point >= node.center) {
      searchHigher = true;
      searchLower = false;

      cur = node.highestEndIndexNode;
      while (cur != 0x0) {
	uint end = _end(node, cur);
	if (end <= point) {
	  break;
	}

	_intervalIDs[num] = uint(node.endIndex.getNodeId(cur));
	num++;

	cur = _previous(node, cur);
      }
    }

    if (num == _intervalIDs.length) {
      intervalIDs = _intervalIDs;
    } else {
      intervalIDs = new uint[](num);
      for (uint i = 0; i < num; i++) {
	intervalIDs[i] = _intervalIDs[i];
      }
    }
  }

  /*
   * constant functions / helpers
   */
  function search(Tree storage tree, uint point)
    constant
    internal
    returns (uint[] memory intervalIDs)
  {
    intervalIDs = new uint[](0);
    uint[] memory tempIDs;
    uint[] memory addedIDs;
    uint i;
    bool searchLower;
    bool searchHigher;

    uint curID = tree.rootNode;
    var curNode = tree.nodes[curID];
    (addedIDs, searchLower, searchHigher) = _searchNode(curNode, point);
    tempIDs = new uint[](intervalIDs.length + addedIDs.length);
    for (i = 0; i < intervalIDs.length; i++) {
      tempIDs[i] = intervalIDs[i];
    }
    for (i = 0; i < addedIDs.length; i++) {
      tempIDs[i + intervalIDs.length] = addedIDs[i];
    }
    intervalIDs = tempIDs;

    while (searchLower || searchHigher) {
      if (searchLower) {
	curID = curNode.nodeBefore;
      } else { // searchHigher
	curID = curNode.nodeAfter;
      }
      if (curID == 0x0) {
	break;
      }

      curNode = tree.nodes[curID];
      (addedIDs, searchLower, searchHigher) = _searchNode(curNode, point);

      tempIDs = new uint[](intervalIDs.length + addedIDs.length);
      for (i = 0; i < intervalIDs.length; i++) {
	tempIDs[i] = intervalIDs[i];
      }
      for (i = 0; i < addedIDs.length; i++) {
	tempIDs[i + intervalIDs.length] = addedIDs[i];
      }
      intervalIDs = tempIDs;
    }
  }

  function intervalsAt(Tree storage tree, uint point) constant returns (uint) {
    return search(tree, point).length;
  }


  function _begin(Node storage node, bytes32 indexNode) constant returns (uint) {
    return getBegin(node.beginIndex.getNodeValue(indexNode));
  }

  function _end(Node storage node, bytes32 indexNode) constant returns (uint) {
    return getEnd(node.endIndex.getNodeValue(indexNode));
  }

  function _next(Node storage node, bytes32 cur) constant returns (bytes32) {
    return node.beginIndex.getNextNode(cur);
  }

  function _previous(Node storage node, bytes32 cur) constant returns (bytes32) {
    return node.endIndex.getPreviousNode(cur);
  }

  function getBeginIndexKey(uint begin) constant internal returns (int) {
    // convert to signed int in order-preserving manner
    return int(begin - 0x8000000000000000000000000000000000000000000000000000000000000000);
  }

  function getEndIndexKey(uint end) constant internal returns (int) {
    // convert to signed int in order-preserving manner
    return int(end - 0x8000000000000000000000000000000000000000000000000000000000000000);
  }

  function getBegin(int beginIndexKey) constant internal returns (uint) {
    // convert to signed int in order-preserving manner
    return uint(beginIndexKey) + 0x8000000000000000000000000000000000000000000000000000000000000000;
  }

  function getEnd(int endIndexKey) constant internal returns (uint) {
    // convert to signed int in order-preserving manner
    return uint(endIndexKey) + 0x8000000000000000000000000000000000000000000000000000000000000000;
  }
}
