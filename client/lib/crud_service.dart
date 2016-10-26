import 'dart:async';
import 'dart:convert';
import 'package:http/browser_client.dart';

class NodeEntity
{
  int nodeId;
  int parentId;
  num value;

  NodeEntity(this.nodeId, this.parentId, this.value);

  static newNode(int parentId)
  {
    return new NodeEntity(null, parentId, 0);
  }

  String toString()
  {
    return 'NodeEntity [nodeId : $nodeId, parentId: $parentId, value: $value]';
  }

}

abstract class CrudService
{
  Future<List<NodeEntity>> readAll();

  Future<NodeEntity> create(NodeEntity node);

  Future<bool> update(NodeEntity node);

  Future<bool> delete(int nodeId);
}

class RestCrudService implements CrudService
{
  static String URL_ALL = '/rest/tree/all';
  static String URL_CREATE = '/rest/tree/create';
  static String URL_UPDATE = '/rest/tree/update';
  static String URL_DELETE = '/rest/tree/delete_id';

  Future<List<NodeEntity>> readAll() async
  {
    print('Crud service refresh all');
    BrowserClient cli = new BrowserClient();
    var response = await cli.get(URL_ALL);
    if (response.statusCode != 200)
    {
      print('Read all request error ${response.statusCode}');
    }
    print('Read all ${response.body}');
    List<Map> nodes = JSON.decode(response.body);
    return new List.from(
      nodes.map((Map m) => new NodeEntity(m['id'], m['parentId'], m['value'])));
  }

  Future<NodeEntity> create(NodeEntity node) async
  {
    print('Crud service create');
    BrowserClient cli = new BrowserClient();
    Map properties = {'id' : null, 'parentId' : node.parentId, 'value' : node.value};
    var response = await cli.put(URL_CREATE, headers: {'content-type':'text/json'}, body: JSON.encode(properties));
    if (response.statusCode == 200)
    {
      print('Create response ${response.body}');
      Map props = JSON.decode(response.body);
      return new NodeEntity(props['id'], props['parentId'], props['value']);
    }
    else
    {
      print('Create response error ${response.statusCode}');
    }
    return null;
  }

  Future<bool> update(NodeEntity node) async
  {
    BrowserClient cli = new BrowserClient();
    Map properties = {'id' : node.nodeId, 'parentId' : node.parentId, 'value' : node.value};
    var response = await cli.put(URL_UPDATE, headers: {'content-type':'text/json'}, body: JSON.encode(properties));
    if (response.statusCode == 200)
    {
      return true;
    }
    return false;
  }

  Future<bool> delete(int nodeId) async
  {
    print('Crud: deleting node $nodeId');
    BrowserClient cli = new BrowserClient();
    var response = await cli.get(URL_DELETE + '/'+nodeId.toString());
    if (response.statusCode == 200)
    {
      return true;
    }
    return false;
  }
}
