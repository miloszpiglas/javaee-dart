import 'dart:collection';
import 'dart:async';
import 'dart:html';

import 'package:client/tree_model.dart';
import 'package:client/crud_service.dart';

/**
 * Service responsble for manipulating tree in database. By default uses implementation
 * of [CrudService] that call CRUD methods from webservice.
 */
class TreeService
{
  Tree tree;
  CrudService crud;
  bool _autoSave = true;
  int unsavedId = 0;
  List<int> scheduleDelete = [];
  bool dirtyState = false;

  WebSocket webSocket = new WebSocket('ws://localhost:9080/changeEvent');

  /**
   * Inits service for given [tree]. All call are forwarded to specific implementation
   * of [CrudService].
   */
  TreeService(Tree tree, CrudService crud)
  {
    this.tree = tree;
    this.crud = crud;

    webSocket.onMessage.listen((MessageEvent e) => dirtyState = true);
  }

  bool get autoSave => _autoSave;

  /**
   * If [auto] is true, all modifications will be saved.
   */
  void set autoSave(bool auto)
  {
    if (auto)
    {
      save();
    }
    _autoSave = auto;
  }

  /**
   * Sends change event to websocket, which will forward it to other open clients.
   */
  void sendEvent()
  {
    if (webSocket != null && webSocket.readyState == WebSocket.OPEN)
    {
      webSocket.send('Model change');
    }
    else
    {
      print('Event not sent ${webSocket.readyState}');
    }
  }

  /**
   * Refresh tree with values from database.
   */
  Future<bool> refreshAll() async
  {
    ListQueue<NodeEntity> allNodes = new ListQueue.from(await crud.readAll());
    tree.clear();
    Set<int> inTree = new Set<int>();
    while (allNodes.isNotEmpty)
    {
      NodeEntity next = allNodes.removeFirst();
      if (next.parentId == null || inTree.contains(next.parentId))
      {
        tree.addNode(next.nodeId, next.parentId, next.value);
        inTree.add(next.nodeId);
      }
    }
    dirtyState = false;
    return true;
  }

  /**
   * Deletes all nodes from tree.
   */
  void deleteAll()
  {
    tree.clear();
  }

  /**
   * Creates new node for given [parentId] (possibly null). New node will have default value.
   * This method works in two modes:
   *  - autosave - all changes are immediatly saved in database
   *  - no autosave - all change since last commit are saved on separate call.
   */
  Future<bool> newNode(int parentId) async
  {
    if (autoSave)
    {
      NodeEntity entity = await crud.create(NodeEntity.newNode(parentId));
      tree.addNode(entity.nodeId, parentId, entity.value);
      sendEvent();
    }
    else
    {
        tree.addNode(--unsavedId, parentId, 0);
        print('Add new node $unsavedId to parent $parentId');
    }
    return true;
  }

  /**
   * Deletes node with given [nodeId].
   * This method works in two modes:
   *  - autosave - all changes are immediatly saved in database
   *  - no autosave - all change since last commit are saved on separate call.
   */
  Future<bool> deleteNode(int nodeId) async
  {
    if (autoSave)
    {
      await crud.delete(nodeId);
      tree.deleteNode(nodeId);
      sendEvent();
    }
    else
    {
      print('Delete node $nodeId');
      tree.markDeleteNode(nodeId);
    }
    return true;
  }

  /**
   * Updates node with given [nodeId] and sets new [value].
   * This method works in two modes:
   *  - autosave - all changes are immediatly saved in database
   *  - no autosave - all change since last commit are saved on separate call.
   */
  Future<bool> updateNode(int nodeId, num value) async
  {
    if (autoSave)
    {
      TreeNode tn = tree.getNode(nodeId);
      await crud.update(new NodeEntity(nodeId, tn.parentId, value));
      tree.updateNode(nodeId, value);
      sendEvent();
    }
    else
    {
      tree.updateNode(nodeId, value);
      if (nodeId >= 0)
      {
        tree.getNode(nodeId).dirty = true;
      }
    }
    return true;
  }

  Future<bool> _saveNewNodes(List<NodeEntity> newNodes) async
  {
    Map<int, int> newIds = {};
    for (NodeEntity nn in newNodes)
    {
      print('Entity to save $nn');
      if (nn.parentId == null || nn.parentId >= 0)
      {
        print('Creating node ${nn.nodeId} in parent ${nn.parentId}');
        NodeEntity sn = await crud.create(nn);
        newIds[nn.nodeId] = sn.nodeId;
      }
      else if (newIds.containsKey(nn.parentId))
      {
        nn.parentId = newIds[nn.parentId];
        print('Creating node ${nn.nodeId}:${nn.parentId}');
        NodeEntity sn = await crud.create(nn);
        newIds[nn.nodeId] = sn.nodeId;
      }
      else
      {
        print('parent with  id ${nn.parentId} is unknown');
      }
    }
    return true;
  }

  /**
   * Saves all changes since last commit.
   */
  Future<bool> save() async
  {
    if (!autoSave && !dirtyState)
    {
      await _saveNewNodes(tree.newNodes.map((n) => new NodeEntity(n.id, n.parentId, n.value)));
      for (NodeEntity e in tree.changedNodes.map((n) => new NodeEntity(n.id, n.parentId, n.value)))
      {
        await crud.update(e);
      }
      for (int nid in tree.deletedNodes)
      {
        await crud.delete(nid);
      }
      refreshAll();
      sendEvent();
      return true;
    }
    return false;
  }
}
