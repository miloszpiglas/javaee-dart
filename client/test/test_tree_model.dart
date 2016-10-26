import "package:test/test.dart";
import "package:client/tree_model.dart";

void main()
{
  test('Simple text', () {expect('abc', equals('abc'));});
  test('Add node to empty tree', shouldAddNodeToEmptyTree);
  test('Add first leaf to non empty tree', shouldAddNodeToNonEmptyTreeFirstLeaf);
  test('add second leaf to non empty tree', shouldAddNodeToNonEmptyTreeSecondLeaf);
  test('should delete leaf', shouldDeleteLeaf);
  test('should delete all', shouldDeleteAll);
  test('should delete branch', shouldDeleteBranch);
}

void shouldAddNodeToEmptyTree()
{
  // given
  Tree tree = new Tree();

  //then
  tree.onTreeChange().listen(
      expectAsync(
        (ModelEvent e)
        {
          expect(e.parentId, isNull);
          expect(e.value, equals(99));
          expect(e.nodeId, equals(5));
          expect(e.level, equals(0));
        }
      )
    );
  // when
  tree.addNode(5, null, 99);
}

void shouldAddNodeToNonEmptyTreeFirstLeaf()
{
  //given
  Tree tree = new Tree();
  tree.addNode(1, null, 10);
  tree.addNode(2, 1, 100);

  // when
  TreeNode newNode = tree.addNode(3, 2, 1000);

  //then
  expect(newNode.id, equals(3));
  expect(newNode.level, equals(2));
  expect(newNode.parent.id, equals(2));
}

void shouldAddNodeToNonEmptyTreeSecondLeaf()
{
  //given
  Tree tree = new Tree();
  tree.addNode(1, null, 10);
  tree.addNode(2, 1, 100);

  // when
  TreeNode newNode = tree.addNode(3, 1, 1000);

  //then
  expect(newNode.id, equals(3));
  expect(newNode.level, equals(1));
  expect(newNode.parent.id, equals(1));
  expect(tree.getNode(1).children, isNotEmpty);
}

void shouldDeleteLeaf()
{
  // given
  Tree tree = new Tree();
  tree.addNode(1, null, 10);
  tree.addNode(2, 1, 100);
  tree.addNode(3, 2, 1000);
  expect(tree.getNode(2).children, isNotEmpty);

  // when
  tree.deleteNode(3);

  // then
  TreeNode node = tree.getNode(2);
  expect(node.children, isEmpty);
}

void shouldDeleteRoot()
{
  // given
  Tree tree = new Tree();
  tree.addNode(1, null, 10);

  // when
  tree.deleteNode(1);

  // then
  expect(tree.isEmpty, isTrue);

}

void shouldDeleteBranch()
{
  // given
  Tree tree = new Tree();
  tree.addNode(1, null, 10);
  tree.addNode(2, 1, 100);
  tree.addNode(3, 2, 1000);
  tree.addNode(4, 1, 200);

  // when
  tree.deleteNode(2);

  // then
  expect(tree.getNode(1).children.length, equals(1));
  expect(tree.getNode(1).children[0].id, equals(4));
}

void shouldDeleteAll()
{
  // given
  Tree tree = new Tree();
  tree.addNode(1, null, 10);
  tree.addNode(2, 1, 100);
  tree.addNode(3, 2, 1000);
  tree.addNode(4, 1, 200);

  // when
  tree.deleteNode(1);

  // then
  expect(tree.isEmpty, isTrue);
}
