pragma solidity ^0.4.15;

import "./vendor/grove/GroveLib.sol";

library IntervalTreeLib {
  using GroveLib for GroveLib.Index;

  bool constant TRAVERSED_EARLIER = false;
  bool constant TRAVERSED_LATER = true;

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

    // if the tree is empty, create the root
    if (tree.rootNode == 0) {
      var nodeID = _createNode(tree, begin, end);
      tree.rootNode = nodeID;

      var node = tree.nodes[nodeID];
      _addIntervalToNode(node, begin, end, intervalID);

      return;
    }

    // depth-first search tree for place to add interval.
    // for each step of the search:
    //   if the new interval contains the current node's center:
    //     add interval to current node
    //     stop search
    //
    //   if the new interval < center:
    //     recurse "before"
    //   if the new interval > center:
    //     recurse "after"
    uint curID = tree.rootNode;
    Node storage curNode = tree.nodes[curID];
    bool found = false;
    while (!found) {
      // track direction of recursion each step, to update correct pointer
      // upon needing to add a new node
      bool recurseDirection;

      if (end <= curNode.center) {
	// traverse before
	curID = curNode.nodeBefore;
	recurseDirection = TRAVERSED_EARLIER;
      } else if (begin > curNode.center) {
	// traverse after
	curID = curNode.nodeAfter;
	recurseDirection = TRAVERSED_LATER;
      } else {
	// found!
	found = true;
	break;
      }

      // if traversing yields null pointer for child node, must create
      if (curID == 0) {
	curID = _createNode(tree, begin, end);

	// update appropriate pointer
	if (recurseDirection == TRAVERSED_EARLIER) {
	  curNode.nodeBefore = curID;
	} else {
	  curNode.nodeAfter = curID;
	}
      }

      // fetch node definition for new curID + update var
      curNode = tree.nodes[curID];
    }

    // loop exits with curNode set to correct location for interval
    // add it!
    _addIntervalToNode(curNode, begin, end, intervalID);
  }

  /*
   * search
   */
  function intervalsAt(Tree storage tree, uint point)
    constant
    returns (uint)
  {
    return search(tree, point).length;
  }

  function intervalAt(Tree storage tree, uint point, uint offset)
    constant
    returns (uint begin, uint end, bytes32 data)
  {
    var results = search(tree, point);

    require(offset < results.length);

    var interval = tree.intervals[results[offset]];

    return (interval.begin, interval.end, interval.data);
  }

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
    var _begin = _getBeginIndexKey(begin);
    var _end = _getEndIndexKey(end);

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

  /*
   * search helpers
   */
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
   * Grove linked list traversal
   */
  function _begin(Node storage node, bytes32 indexNode) constant returns (uint) {
    return _getBegin(node.beginIndex.getNodeValue(indexNode));
  }

  function _end(Node storage node, bytes32 indexNode) constant returns (uint) {
    return _getEnd(node.endIndex.getNodeValue(indexNode));
  }

  function _next(Node storage node, bytes32 cur) constant returns (bytes32) {
    return node.beginIndex.getNextNode(cur);
  }

  function _previous(Node storage node, bytes32 cur) constant returns (bytes32) {
    return node.endIndex.getPreviousNode(cur);
  }

  /*
   * uint / int conversions for Grove nodeIDs
   */
  function _getBeginIndexKey(uint begin) constant internal returns (int) {
    // convert to signed int in order-preserving manner
    return int(begin - 0x8000000000000000000000000000000000000000000000000000000000000000);
  }

  function _getEndIndexKey(uint end) constant internal returns (int) {
    // convert to signed int in order-preserving manner
    return int(end - 0x8000000000000000000000000000000000000000000000000000000000000000);
  }

  function _getBegin(int beginIndexKey) constant internal returns (uint) {
    // convert to unsigned int in order-preserving manner
    return uint(beginIndexKey) + 0x8000000000000000000000000000000000000000000000000000000000000000;
  }

  function _getEnd(int endIndexKey) constant internal returns (uint) {
    // convert to unsigned int in order-preserving manner
    return uint(endIndexKey) + 0x8000000000000000000000000000000000000000000000000000000000000000;
  }
}
