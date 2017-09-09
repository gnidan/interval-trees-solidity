pragma solidity ^0.4.15;

import "./vendor/grove/GroveLib.sol";

import "./IntervalLib.sol";
import "./IntervalListLib.sol";

library IntervalTreeLib {
  using GroveLib for GroveLib.Index;
  using IntervalLib for IntervalLib.Interval;
  using IntervalListLib for IntervalListLib.List;

  bool constant TRAVERSED_EARLIER = false;
  bool constant TRAVERSED_LATER = true;

  uint8 constant SEARCH_DONE = 0x00;
  uint8 constant SEARCH_EARLIER = 0x01;
  uint8 constant SEARCH_LATER = 0x10;

  struct Tree {
    // global table of intervals
    mapping (uint => IntervalLib.Interval) intervals;
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

    IntervalListLib.List intervals;
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
    returns (uint count)
  {
    count = search(tree, point).length;
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
    // can't search empty trees
    require(tree.rootNode != 0x0);

    // HACK repeatedly mallocs new arrays of matching interval IDs
    intervalIDs = new uint[](0);
    uint[] memory tempIDs;
    uint[] memory matchingIDs;
    uint i;  // for list copying loops

    /*
     * search traversal
     *
     * starting at root node
     */
    uint curID = tree.rootNode;
    uint8 searchNext;
    do {
      Node storage curNode = tree.nodes[curID];

      /*
       * search current node
       */
      (matchingIDs, searchNext) = _searchNode(curNode, point);

      /*
       * add matching intervals to results array
       *
       * allocate temp array and copy in both prior and new matches
       */
      if (matchingIDs.length > 0) {
	tempIDs = new uint[](intervalIDs.length + matchingIDs.length);
	for (i = 0; i < intervalIDs.length; i++) {
	  tempIDs[i] = intervalIDs[i];
	}
	for (i = 0; i < matchingIDs.length; i++) {
	  tempIDs[i + intervalIDs.length] = matchingIDs[i];
	}
	intervalIDs = tempIDs;
      }

      /*
       * recurse according to node search results
       */
      if (searchNext == SEARCH_EARLIER) {
	curID = curNode.nodeBefore;
      } else if (searchNext == SEARCH_LATER) { // SEARCH_LATER
	curID = curNode.nodeAfter;
      }

    } while (searchNext != SEARCH_DONE && curID != 0x0);
  }


  /*
   * insert helpers
   */
  function _createInterval(Tree storage tree, uint begin, uint end, bytes32 data)
    internal
    returns (uint intervalID)
  {
    intervalID = ++tree.numIntervals;

    tree.intervals[intervalID] = IntervalLib.Interval({
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
      intervals: IntervalListLib.createNew(nodeID)
    });
  }

  function _addIntervalToNode(Node storage node, uint begin, uint end, uint intervalID) {
    var _intervalID = bytes32(intervalID);
    var _begin = _getBeginIndexKey(begin);
    var _end = _getEndIndexKey(end);

    node.intervals.beginIndex.insert(_intervalID, _begin);
    node.intervals.endIndex.insert(_intervalID, _end);
    node.count++;

    if (node.count == 1) {
      node.intervals.lowestBegin = node.intervals.beginIndex.root;
      node.intervals.highestEnd = node.intervals.endIndex.root;

      return;
    }

    var newLowest = node.intervals.beginIndex.getPreviousNode(node.intervals.lowestBegin);
    if (newLowest != 0x0) {
      node.intervals.lowestBegin = newLowest;
    }

    var newHighest = node.intervals.endIndex.getNextNode(node.intervals.highestEnd);
    if (newHighest != 0x0) {
      node.intervals.highestEnd = newHighest;
    }
  }

  /*
   * search helpers
   */

  /*
   * @dev Searches node for matching intervals and how to search next
   * @param node The node to search
   * @param point The point to search for
   */
  function _searchNode(Node storage node, uint point)
    constant
    internal
    returns (uint[] memory intervalIDs, uint8 searchNext)
  {
    uint[] memory _intervalIDs = new uint[](node.count);
    uint num = 0;

    bytes32 cur;

    if (point == node.center) {
      /*
       * case: point exactly matches the node's center
       *
       * collect (all) matching intervals (every interval in node, by def)
       */
      cur = node.intervals.lowestBegin;
      while (cur != 0x0) {
	_intervalIDs[num] = uint(node.intervals.beginIndex.getNodeId(cur));
	num++;
	cur = _next(node, cur);
      }

      /*
       * search is done:
       * no other nodes in tree have intervals containing point
       */
      searchNext = SEARCH_DONE;
    } else if (point < node.center) {
      /*
       * case: point is earlier than center.
       *
       *
       * collect matching intervals.
       *
       * shortcut:
       *
       *   starting with lowest beginning interval, search sorted begin list
       *   until begin is later than point
       *
       *	       point
       *                 :
       *                 :   center
       *                 :     |
       *        (0) *----:-----|----------o
       *        (1)    *-:-----|---o
       *        (-)      x *---|------o
       *        (-)         *--|--o
       *        (-)          *-|----o
       *
       *
       *    this works because intervals contained in a node are guaranteed to
       *    contain `center`
       */
      cur = node.intervals.lowestBegin;
      while (cur != 0x0) {
	uint begin = _begin(node, cur);
	if (begin > point) {
	  break;
	}

	_intervalIDs[num] = uint(node.intervals.beginIndex.getNodeId(cur));
	num++;

	cur = _next(node, cur);
      }

      /*
       * search proceeds to node containing earlier intervals
       */
      searchNext = SEARCH_EARLIER;
    } else if (point > node.center) {
      /*
       * case: point is later than center.
       *
       *
       * collect matching intervals.
       *
       * shortcut:
       *
       *   starting with highest ending interval, search sorted end list
       *   until end is earlier than or equal to point
       *
       *			    point
       *			    :
       *                     center :
       *                       |    :
       *            *----------|----:-----o (0)
       *                   *---|----:-o     (1)
       *                     *-|----o	    (not matching, done.)
       *               *-------|---o	    (-)
       *                    *--|--o	    (-)
       *
       *
       *    this works because intervals contained in a node are guaranteed to
       *    contain `center`
       */
      cur = node.intervals.highestEnd;
      while (cur != 0x0) {
	uint end = _end(node, cur);
	if (end <= point) {
	  break;
	}

	_intervalIDs[num] = uint(node.intervals.endIndex.getNodeId(cur));
	num++;

	cur = _previous(node, cur);
      }

      /*
       * search proceeds to later intervals
       */
      searchNext = SEARCH_LATER;
    }

    /*
     * return correctly-sized array of intervalIDs
     */
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
    return _getBegin(node.intervals.beginIndex.getNodeValue(indexNode));
  }

  function _end(Node storage node, bytes32 indexNode) constant returns (uint) {
    return _getEnd(node.intervals.endIndex.getNodeValue(indexNode));
  }

  function _next(Node storage node, bytes32 cur) constant returns (bytes32) {
    return node.intervals.beginIndex.getNextNode(cur);
  }

  function _previous(Node storage node, bytes32 cur) constant returns (bytes32) {
    return node.intervals.endIndex.getPreviousNode(cur);
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
