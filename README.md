Interval Trees in Solidity
==========================

Provides an implementation of the [Interval tree](https://en.wikipedia.org/wiki/Interval_tree)
data structure, as a library for use in smart contracts.

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

*See [Example.sol](https://github.com/gnidan/interval-trees-solidity/blob/master/contracts/Example.sol) for a contract that maintains a global collection of interval trees.*


#### `tree.addInterval(uint begin, uint end, bytes32 data)`

- **internal**

Adds an interval `[begin, end)` with `data`.


#### `tree.search(uint point)`

- **constant**
- **internal**
- **returns** `(uint[] memory matchingIDs)`

Searches the tree for intervals containing `point`.

Returns memory array of interval IDs, to retrieve with `tree.getInterval()`


#### `tree.getInterval(uint intervalID)`

- **constant**
- **internal**
- **returns** `(uint begin, uint end, bytes32 data)`

Retrieves interval information for a given interval ID.

Use in conjunction with `tree.search()`.


Notes / Status
--------------

- Supports adding new intervals and finding intervals containing a point
- No support currently for interval search
- Creates unbalanced trees

This project uses @pipermerriam's [Grove](https://github.com/pipermerriam/ethereum-grove)
data structure for some underlying behavior.
