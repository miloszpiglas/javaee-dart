import 'dart:async';

/**
 * Representation of node of tree.
 */
class TreeNode
{
  /// tree identifier
  int id;
  /// tree parent
  TreeNode parent;
  /// nodes level. Root's level is 0.
  int level;
  /// value of node
  num value;
  /// node's children
  List<TreeNode> children = [];
  /// node contains values that was not saved in database
  bool dirty = false;
  /// node is marked for deletion
  bool deleted = false;
  TreeNode(this.id, this.parent, this.value, this.level);

  int get parentId => parent != null ? parent.id : null;
}

/**
 * Client representation of tree.
 */
class Tree
{
  TreeNode _root = null;
  TreeNode _deletedRoot = null;
  StreamController<ModelEvent> _onTreeChangeCtrl = new StreamController<ModelEvent>();

  /**
   * Returns node with given id or null, if node is not found.
   */
  TreeNode getNode(int id)
  {
    return findNode(_root, id);
  }

  /**
   * Returns list of nodes that were modified since last commit.
   */
  List<TreeNode> get changedNodes
  {
    print('List of changed nodes');
    if (_root == null)
    {
      return [];
    }
    return _collect(_root, (node) => node.dirty);
  }

  /**
   * Returns list of nodes that were created since last commit.
   */
  List<TreeNode> get newNodes
  {
    print('List of new nodes');
    if (_root == null)
    {
      return [];
    }
    List<TreeNode> result = _collect(_root, (node) => node.id < 0);
    return result;
  }

  /**
   * Returns list of nodes that were deleted since last commit.
   */
  List<int> get deletedNodes
  {
    if (_deletedRoot != null)
    {
      print('Root is deleted ${_deletedRoot.id}');
      return [_deletedRoot.id];
    }
    List<int> result = _collectDeleted(_root);
    print('Tree model: deleted nodes $result');
    return result;
  }

  List<int> _collectDeleted(TreeNode current)
  {
    if (current.deleted)
    {
      print('Deleted node ${current.id}');
      return [current.id];
    }
    else
    {
      List<int> result = [];
      for (TreeNode ch in current.children)
      {
        result.addAll(_collectDeleted(ch));
      }
      return result;
    }
  }

  List<TreeNode> _collect(TreeNode current, bool test(TreeNode node))
  {
    List<TreeNode> result = [];
    if (current.deleted)
    {
      return result;
    }
    if (test(current))
    {
      result.add(current);
    }
    for (TreeNode ch in current.children)
    {
      result.addAll(_collect(ch, test));
    }
    return result;
  }

  /**
   * Adds node with given [id] to tree. Operation triggers new [ModelEvent].
   */
  TreeNode addNode(int id, int parentId, num value)
  {
    if (_root == null)
    {
      _root = new TreeNode(id, null, value, 0);
      _onTreeChangeCtrl.add(new ModelEvent(null, id, value, 0, 'A', value));
      return _root;
    }
    else
    {
      TreeNode parent = findNode(_root, parentId);
      if (parent != null)
      {
        if (parent.children.isEmpty)
        {
          // parent is no longer tree's leaf, so we have to update it, since it
          // contains sum of it ancestors.
          _onTreeChangeCtrl.add(new ModelEvent(parent.parentId, parent.id, parent.value, parent.level, 'U', parent.value));
        }
        TreeNode tn = new TreeNode(id, parent, value, parent.level + 1);
        parent.children.add(tn);
        // new node added as leaf will contain sum of its ancestors.
        _onTreeChangeCtrl.add(new ModelEvent(tn.parentId, id, _calcSum(tn), tn.level, 'A', tn.value));
        return tn;
      }
      return null;
    }
  }

  /**
   * Calculates sum of ancestors of [node].
   */
  num _calcSum(TreeNode node)
  {
    if (node.parent != null)
    {
      num parentSum = _calcSum(node.parent);
      if (node.children.isNotEmpty)
      {
        parentSum += node.value;
      }
      return parentSum;
    }
    return node.value;
  }

  /**
   * Schedul node for removal. Selected node is kept in tree, but its children are
   * removed from memory. This method is called when 'auto-save' mode is disabled.
   */
  bool markDeleteNode(int id)
  {
    TreeNode node = findNode(_root, id);
    if (node != null && node.parentId != null)
    {
      TreeNode parent = findNode(_root, node.parentId);
      _deleteSubnodes(node);
      if (node.id >= 0)
      {
        node.deleted = true;
      }
      else
      {
        parent.children.remove(node);
      }
      _onTreeChangeCtrl.add(new ModelEvent(node.parentId, node.id, node.value,
        node.level, 'D', node.value));
      if (parent.children.isEmpty)
      {
        _onTreeChangeCtrl.add(new ModelEvent(parent.parentId, parent.id, _calcSum(parent),
          parent.level, 'U', parent.value));
      }
      return true;
    }
    else if (node != null)
    {
      if (node.id >= 0)
      {
        _deletedRoot = _root;
      }
      _root = null;
      _deleteSubnodes(node);
      _onTreeChangeCtrl.add(new ModelEvent(node.parentId, node.id, node.value, node.level, 'D', node.value));
      return true;
    }
    return false;
  }

  /**
   * Deletes node and its children from tree.
   */
  bool deleteNode(int id)
  {
    TreeNode node = findNode(_root, id);
    if (node != null && node.parentId != null)
    {
      TreeNode parent = findNode(_root, node.parentId);
      _deleteSubnodes(node);
      parent.children.remove(node);
      _onTreeChangeCtrl.add(new ModelEvent(node.parentId, node.id, node.value,
        node.level, 'D', node.value));
      if (parent.children.isEmpty)
      {
        _onTreeChangeCtrl.add(new ModelEvent(parent.parentId, parent.id, _calcSum(parent),
        parent.level, 'U', parent.value));
      }
      return true;
    }
    else if (node != null)
    {
      _root = null;
      _deleteSubnodes(node);
      _onTreeChangeCtrl.add(new ModelEvent(node.parentId, node.id, node.value,
        node.level, 'D', node.value));
      return true;
    }
    return false;
  }

  bool get isEmpty => _root == null;

  void clear()
  {
    if (!isEmpty)
    {
      deleteNode(_root.id);
      _deletedRoot = null;
    }
  }

  /**
   * Deletes children of node.
   */
  void _deleteSubnodes(TreeNode node)
  {
    while (!node.children.isEmpty)
    {
      TreeNode child = node.children.last;
      if (!child.deleted)
      {
        _deleteSubnodes(child);
        node.children.removeLast();
        _onTreeChangeCtrl.add(new ModelEvent(child.parentId, child.id, child.value,
          child.level, 'D', child.value));
      }
    }
  }

  /**
   * Updates node with given value.
   */
  bool updateNode(int nodeId, num value)
  {
    TreeNode node = findNode(_root, nodeId);
    if (node != null)
    {
      node.value = value;
      _onTreeChangeCtrl.add(new ModelEvent(node.parentId, node.id, node.value,
        node.level, 'U', node.value));
      refreshChildren(node);
      return true;
    }
    return false;
  }

  /**
   * Refresh children of node. If node doesn't have children, it will be displaying
   * sum of its ancestors.
   */
  void refreshChildren(TreeNode current)
  {
    if (current.children.isEmpty)
    {
      _onTreeChangeCtrl.add(new ModelEvent(current.parentId, current.id,
        _calcSum(current), current.level, 'U', current.value));
    }
    else
    {
      for (TreeNode ch in current.children)
      {
        refreshChildren(ch);
      }
    }
  }

  /**
   * Browse tree for node with given id.
   */
  TreeNode findNode(TreeNode current, int nodeId)
  {
    if (current.deleted)
    {
      return null;
    }
    if (current.id == nodeId)
    {
      return current;
    }
    else
    {
      for (TreeNode n in current.children)
      {
        TreeNode tn = findNode(n, nodeId);
        if (tn != null)
        {
          return tn;
        }
      }
      return null;
    }
  }

  /**
   * Streams tree change events to listeners.
   */
  Stream<ModelEvent> onTreeChange()
  {
    return _onTreeChangeCtrl.stream;
  }
}

/**
 * Event generated when tree changes. Note that single operation migh trigger sequence
 * of events.
 */
class ModelEvent
{
  int parentId;
  num value;
  int nodeId;
  int level;
  String type;
  num realValue;
  ModelEvent(this.parentId, this.nodeId, this.value, this.level, this.type, this.realValue);
}
