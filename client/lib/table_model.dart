import 'dart:async';
import 'package:client/tree_model.dart';

/**
 * Represents table's row. Stores information about underlying tree nodes.
 */
class TableRow
{
  int parentId;
  int nodeId;
  int level;
  num value;
  TableRow(this.parentId, this.nodeId, this.level, this.value);
}

/**
 * Event generated when table's model changes. Single change in model might trigger one
 * or more events.
 */
class TableEvent
{
  /// index of row
  int index;
  /// table's row
  TableRow row;
  /// type of event
  String type;
  /// real value of node. If row represents tree's leaf it displays sum of its
  /// ascendants.
  num realValue;

  TableEvent(this.index, this.row, this.type, this.realValue);
}

/**
 * Role of table model is to 'translate' tree structure to flat table representation.
 * Listen for changes in tree, updates rows and triggers events to listeners.
 */
class TableModel
{
  List<TableRow> rows = [];
  Tree _tree;
  StreamController<TableEvent> _onModelChangeCtrl = new StreamController<TableEvent>();
  TableModel(Tree tree)
  {
    this._tree = tree;
    this._tree.onTreeChange().listen(_onTreeChange);
  }

  /**
   * Listen for changes in tree and frowards calls to specific methods.
   */
  void _onTreeChange(ModelEvent node)
  {
    print('New model event ${node.type}');
    if (node.type == 'U')
    {
      _nodeUpdated(node);
    }
    else if (node.type == 'D')
    {
      _nodeDeleted(node);
    }
    else if (node.type == 'A')
    {
      _nodeAdded(node);
    }
  }

  /**
   * Called when tree node is updated.
   */
  void _nodeUpdated(ModelEvent node)
  {
    for (int i = 0; i < rows.length; i++)
    {
      if (rows[i].nodeId == node.nodeId)
      {
        rows[i].value = node.value;
        _onModelChangeCtrl.add(new TableEvent(i, rows[i], 'U', node.realValue));
      }
    }
  }

  /**
   * Called when tree node is deleted.
   */
  void _nodeDeleted(ModelEvent node)
  {
    for (int i = 0; i < rows.length; i++)
    {
      if (rows[i].nodeId == node.nodeId)
      {
        _onModelChangeCtrl.add(new TableEvent(i, rows.removeAt(i), 'D', node.realValue));
        return;
      }
    }
  }

  /**
   * Called when new node is added.
   */
  void _nodeAdded(ModelEvent node)
  {
    if (node.level == 0)
    {
      // root node
      TableRow tr = new TableRow(null, node.nodeId, 0, node.value);
      rows.add(tr);
      _onModelChangeCtrl.add(new TableEvent(0, tr, 'A', node.realValue));
    }
    else
    {
      int parentIndex = -1;
      for (int i = 0; i < rows.length; i++)
      {
        if (rows[i].nodeId == node.parentId)
        {
          parentIndex = i;
          break;
        }
      }
      if (parentIndex >= 0 && parentIndex < rows.length-1)
      {
        // after row which contains parent there are more rows, so we inser new
        // row after parent
        TableRow tr = new TableRow(node.parentId, node.nodeId, node.level, node.value);
        rows.insert(parentIndex+1, tr);
        _onModelChangeCtrl.add(new TableEvent(parentIndex+1, tr, 'A', node.realValue));
      }
      else if (parentIndex >= 0)
      {
        // parent is a last row in table
        TableRow tr = new TableRow(node.parentId, node.nodeId, node.level, node.value);
        rows.add(tr);
        _onModelChangeCtrl.add(new TableEvent(parentIndex+1, tr, 'A', node.realValue));
      }
    }
  }

  /**
   * Streams table events to listeners.
   */
  Stream<TableEvent> onModelChange()
  {
    return _onModelChangeCtrl.stream;
  }
}
