import 'dart:html';
import 'dart:async';
import 'package:client/tree_model.dart';
import 'package:client/tree_service.dart';
import 'package:client/table_model.dart';
import 'package:client/crud_service.dart';

/**
 * Representation of event that is sent to listeners when selection changes in tree.
 */
class SelectionEvent
{
  String value;

  /**
   * New instance with [value] of selected node. Value might be null when all nodes
   * are deselected.
   */
  SelectionEvent(this.value);
}

/**
 * Component responsiple for rendering tree in HTML document.
 */
class TreeTableComponent
{
  TableModel model;
  TableRowElement selected = null;
  StreamController<SelectionEvent> _onSelectionChangeCtrl = new StreamController<SelectionEvent>();
  int maxLevel = 0;

  /**
   * Component uses common HTML table to render underlying [tree].
   *
   * Each row of table represents single node of tree.
   */
  TreeTableComponent(Tree tree)
  {
    model = new TableModel(tree);
    model.onModelChange().listen(_onModelChange);
  }

  /**
   * Listener method called when underlying table model has changed.
   */
  void _onModelChange(TableEvent event)
  {
    if (event.type == 'A')
    {
      _onAddRow(event);
    }
    else if (event.type == 'U')
    {
      _onUpdateRow(event);
    }
    else if (event.type == 'D')
    {
      _onDeleteRow(event);
    }
  }

  /// table used to render tree
  TableElement get htmlTable => querySelector('#tree_table');

  /// identifier of selected node.
  int get selectedId => int.parse(selected.cells[0].text);

  /**
   * Called when row in underlying model is updated.
   * Updates proper cell in HTML table with value from [event].
   */
  void _onUpdateRow(TableEvent event)
  {
    TableRowElement row = htmlTable.rows[event.index];
    TableCellElement cell = row.cells[3 + event.row.level];
    cell.text = event.row.value.toString();
    row.cells[2].text = event.realValue.toString();
  }

  /**
   * Called when row in uderlying model is deleted.
   * Removes from HTML table row at index from [event].
   */
  void _onDeleteRow(TableEvent event)
  {
    htmlTable.deleteRow(event.index);
  }

  /**
   * Called when new row is added to underlying model.
   */
  void _onAddRow(TableEvent event)
  {
    var rindex = event.index;
    if (rindex == 0)
    {
      // root node
      TableElement table = htmlTable;
      _createRow(table.addRow(), event);
      maxLevel = 0;
    }
    else
    {
      TableElement table = htmlTable;
      int newLevel = _createRow(table.insertRow(rindex), event);
      for (int r = 0; r < table.rows.length; r++)
      {
        if (rindex != r)
        {
          // in case new height of tree changes, more cells must be
          // added to HTML table.
          var tr = table.rows[r];
          for (int c = 0; c < newLevel - maxLevel; c++)
          {
            tr.addCell().text = '';
          }
        }
      }
      maxLevel = newLevel;
    }
  }

  int _createRow(TableRowElement tabRow, TableEvent tabEvent)
  {
    TableRow eventRow = tabEvent.row;
    tabRow.onClick.listen(_selectionListener);
    var cellId = tabRow.addCell();
    cellId.text = eventRow.nodeId.toString();
    cellId.hidden = true;

    var cellParent = tabRow.addCell();
    cellParent.text = eventRow.parentId != null ? eventRow.parentId.toString() : '';
    cellParent.hidden = true;

    var cellValue = tabRow.addCell();
    cellValue.text = tabEvent.realValue.toString();
    cellValue.hidden = true;

    for (int p = 0; p < eventRow.level; p++)
    {
      tabRow.addCell().text = '';
    }
    if (tabRow.cells.length > 3)
    {
      tabRow.cells.last.text = '-';
    }
    tabRow.addCell().text = eventRow.value.toString();
    return eventRow.level;
  }

  /**
   * Listen of mouse events in document. If user click on table, row is higlighted.
   */
  void _selectionListener(MouseEvent event)
  {
    if (event.target is TableRowElement)
    {
      _selectRow(event.target);
    }
    else if (event.target is TableCellElement)
    {
      TableCellElement cell = event.target;
      _selectRow(cell.parent);
    }
  }

  void _selectRow(TableRowElement selectedRow)
  {
    if (selected != null)
    {
      selected.style.background = 'white';
    }
    selected = selectedRow;
    selected.style.background = 'yellow';
    _onSelectionChangeCtrl.add(new SelectionEvent(selected.cells[2].text));
  }

  /**
   * Remove selection.
   */
  void clearSelection()
  {
    selected = null;
    _onSelectionChangeCtrl.add(new SelectionEvent(null));
  }

  /**
   * Streams selection events to listener.
   */
  Stream<SelectionEvent> onSelectionChange()
  {
    return _onSelectionChangeCtrl.stream;
  }
}

/**
 * Main view of table. Contains operation buttons and table, used for rendering
 * tree, which is controlled by [TreeTableComponent]. For managing tree [TreeService] is used.
 */
class TreeTable
{
  TreeService _treeSrv;
  TreeTableComponent tabComponent;
  bool inputValid = true;

  TreeTable()
  {
    _initComponents();
    Tree tree = new Tree();
    _treeSrv = new TreeService(tree, new RestCrudService());
    tabComponent = new TreeTableComponent(tree);
    tabComponent.onSelectionChange().listen(_onSelectionChange);
    _treeSrv.refreshAll();
  }


  void _initComponents()
  {
    _initButtons();
    _initCheckBox();
    _initInput();
  }

  void _initInput()
  {
    TextInputElement input = querySelector('#update_input');
    input.onInput.listen(_onInputChange);
  }

  void _initButtons()
  {
    _setClickAction('#add_btn', _onAdd);
    _setClickAction('#delete_btn', _onDelete);
    _setClickAction('#update_btn', _onUpdate);
    _setClickAction('#reload_btn', _onReload);
    _setClickAction('#save_btn', _onSave);
    _setClickAction('#revert_btn', _onReload);
  }

  void _initCheckBox()
  {
    CheckboxInputElement cbAutosave = querySelector('#autosave_cb');
    if (cbAutosave != null)
    {
      cbAutosave.onChange.listen(_onAutoSave);
    }
  }

  /**
   * Registers mouse [event] listener on button with given [selector].
   */
  void _setClickAction(String selector, void onClick(MouseEvent event))
  {
    ButtonElement btn = querySelector(selector);
    if (btn != null)
    {
      btn.onClick.listen(onClick);
    }
  }

  /**
   * Clears selection and reloads nodes from database. This event is called when
   * user clicks button 'Reload'.
   */
  void _onReload(MouseEvent event)
  {
    print('On reload');
    tabComponent.clearSelection();
    _treeSrv.refreshAll();
    _setMessage('');
  }

  void _setMessage(String msgTxt)
  {
    ParagraphElement msg = querySelector('#message');
    msg.text = msgTxt;
  }

  /**
   * Called when user clicks button 'Add'.
   *
   * Adds new leaf to selected node or root node.
   * This action won't be executed, if displayed model is not synchronized with database.
   */
  void _onAdd(MouseEvent event)
  {
    print('On add');
    if (_treeSrv.dirtyState && _treeSrv.autoSave)
    {
      _setMessage('Underlying model has changed. Please reload tree');
      return;
    }
    if (tabComponent.selected != null)
    {
      _treeSrv.newNode(tabComponent.selectedId);
    }
    else
    {
      _treeSrv.newNode(null);
    }
  }

  /**
   * Called when user click button 'Delete'.
   *
   * Deletes selected node and its children from tree. This action won't
   * be executed, if displayed model is not synchronized with database.
   */
  void _onDelete(MouseEvent event)
  {
    if (_treeSrv.dirtyState && _treeSrv.autoSave)
    {
      _setMessage('Underlying model has changed. Please reload tree');
      return;
    }
    if (tabComponent.selected != null)
    {
      _treeSrv.deleteNode(tabComponent.selectedId);
    }
  }

  /**
   * Called when user click button 'Update'.
   *
   * Updates selected node in tree tree. This action won't
   * be executed, if displayed model is not synchronized with database.
   */
  void _onUpdate(MouseEvent event)
  {
    if (_treeSrv.dirtyState && _treeSrv.autoSave)
    {
      _setMessage('Underlying model has changed. Please reload tree');
      return;
    }
    if (!inputValid)
    {
      return;
    }
    TextInputElement input = querySelector('#update_input');
    if (tabComponent.selected != null)
    {
      _treeSrv.updateNode(tabComponent.selectedId, num.parse(input.value));
    }
  }

  /**
   * Validates text field and checks if inserted value might be parsed as number.
   * If value is invalid, text field is highlighted.
   */
  void _onInputChange(Event event)
  {
    print('input change ');
    TextInputElement input = querySelector('#update_input');
    String txt = input.value;
    // if txt cannot be parsed, method will return null.
    num number = num.parse(txt, (src) => null);
    if (txt.isEmpty || number == null)
    {
      print('Invalid input $txt');
      input.style.backgroundColor = 'red';
      inputValid = false;
    }
    else
    {
      inputValid = true;
      input.style.backgroundColor = 'white';
    }
  }

  /**
   * Method called when user changes selection in tree.
   */
  void _onSelectionChange(SelectionEvent event)
  {
    print('selection change');
    TextInputElement input = querySelector('#update_input');
    if (event.value != null)
    {
      input.value = event.value;
      inputValid = true;
    }
    else
    {
      input.value = '';
      inputValid = true;
    }
    input.style.backgroundColor = 'white';
  }

  /**
   * Called when user click 'Save' button.
  * Saves all changes performed after last commit. This action won't
  * be executed, if displayed model is not synchronized with database.
  */
  void _onSave(MouseEvent event)
  {
    if (_treeSrv.dirtyState)
    {
      _setMessage('Underlying model has changed. Please reload tree');
      return;
    }
    _treeSrv.save();
  }

  void _onAutoSave(Event event)
  {
    CheckboxInputElement cbAutoSave = querySelector('#autosave_cb');
    if (cbAutoSave.checked && _treeSrv.dirtyState)
    {
      _setMessage('Underlying model has changed. Please reload tree');
      cbAutoSave.checked = false;
      return;
    }
    print('On autosave chage. Checked: ${cbAutoSave.checked}');
    _treeSrv.autoSave = cbAutoSave.checked;
  }
}
