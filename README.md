Interval Trees in Solidity
==========================

Provides [Interval tree](https://en.wikipedia.org/wiki/Interval_tree) library
for use in smart contracts.

API
---

### TreeLib

File [`contracts/intervals/TreeLib.sol`](https://github.com/gnidan/interval-trees-solidity/blob/master/contracts/intervals/TreeLib.sol)

**Usage**: import library and use for `TreeLib.Tree` data structure.

```javascript
contract HasTree {
  using TreeLib for TreeLib.Tree;

  TreeLib.Tree tree;

  function HasTree() {
    tree.addInterval(5, 9, 0xDEADBEEF);
  }
}
```


#### `addInterval(Tree storage tree, uint begin, uint end, bytes32 data)`

Adds an interval `[begin, end)` with `data`.


#### `search(Tree storage tree, uint point) constant returns (uint[] memory matchingIDs)`

Searches the tree for intervals containing `point`.

Returns memory array of interval IDs.


#### `getInterval(Tree storage tree, uint intervalID) constant returns (uint begin, uint end, bytes32 data)`

Retrieves interval information for a given interval ID.

Use in conjunction with `tree.search()`.
