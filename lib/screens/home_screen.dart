import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../models/food_item.dart';
import '../services/food_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<FoodItem> items;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  _fetchItems() => items = FoodService.getAllFoodItems();

  _copyToClipboardAsCSV() {
    final csv = _generateCSV(Hive.box<FoodItem>('foodBox').values.toList());
    Clipboard.setData(ClipboardData(text: csv));
  }

  String _generateCSV(List<FoodItem> items) {
    return [
      ["Name", "Amount", "Unit"],
      ...items.map((item) => [item.name, item.amount.toString(), item.unit])
    ].map((e) => e.join(',')).join('\n');
  }

  List<FoodItem> _parseCsv(String csvContent) {
    final lines = csvContent.split('\n').skip(1).where((line) => line.isNotEmpty).toList();
    return lines.map((line) {
      final values = line.split(',');
      final name = values[0];
      final amount = double.tryParse(values[1]) ?? 0.0;
      final unit = values[2];
      return FoodItem(name: name, amount: amount, unit: unit);
    }).toList();
  }

  Future<void> _clearBox() async {
    final box = await Hive.openBox<FoodItem>('foodBox');
    await box.clear();
    _fetchItems();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _buildAppBar(),
        body: _buildListView(),
        floatingActionButton: _buildAddButton(),
      );

  AppBar _buildAppBar() => AppBar(
        title: const Text("Essens Inventar"),
        backgroundColor: Colors.green,
        actions: [
          _buildAppBarButton("CSV Kopieren", _copyToClipboardAsCSV),
          _buildAppBarButton("CSV Einfügen", _showCsvImportDialog),
          _buildAppBarButton("Zurücksetzen", _clearBox),
        ],
      );

  ElevatedButton _buildAppBarButton(String label, VoidCallback onPressed) =>
      ElevatedButton(child: Text(label), onPressed: onPressed);

  ListView _buildListView() => ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => _buildListItem(index),
      );

  ListTile _buildListItem(int index) {
    final item = items[index];
    return ListTile(
      title: Text(item.name),
      subtitle: Text('${item.amount} ${item.unit}'),
      onTap: () => _showUpdateDialog(item, index),
      trailing: _buildDeleteIcon(item, index),
    );
  }

  IconButton _buildDeleteIcon(FoodItem item, int index) => IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          FoodService.removeFoodItem(item);
          setState(() => items.removeAt(index));
        },
      );

  FloatingActionButton _buildAddButton() => FloatingActionButton(
    backgroundColor: Colors.green,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      );

  Future<void> _showCsvImportDialog() async {
    String csvContent = '';
    await showDialog(
      context: context,
      builder: (context) => _buildCsvImportDialog(csvContent),
    );
  }

  AlertDialog _buildCsvImportDialog(String csvContent) => AlertDialog(
        title: Text("CSV Einfügen"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Füge deine CSV hier ein:"),
            TextField(
              maxLines: 10,
              onChanged: (value) => csvContent = value,
              decoration: InputDecoration(hintText: "Name,Amount,Unit"),
            ),
          ],
        ),
        actions: [
          _buildDialogButton("Abbrechen", () => Navigator.pop(context)),
          _buildDialogButton("Import", () {
            final newItems = _parseCsv(csvContent);
            for (var item in newItems) {
              FoodService.addFoodItem(item);
            }
            _fetchItems();
            setState(() {});
            Navigator.pop(context);
          }),
        ],
      );

  TextButton _buildDialogButton(String label, VoidCallback onPressed) =>
      TextButton(child: Text(label), onPressed: onPressed);

  Future<void> _showAddDialog() async {
    final newItem = await showDialog<FoodItem>(
      context: context,
      builder: (context) => FoodItemDialog(),
    );
    if (newItem != null) {
      FoodService.addFoodItem(newItem);
      setState(() => items.add(newItem));
    }
  }

  Future<void> _showUpdateDialog(FoodItem item, int index) async {
    final updatedItem = await showDialog<FoodItem>(
      context: context,
      builder: (context) => FoodItemDialog(originalItem: item),
    );
    if (updatedItem != null) {
      FoodService.updateFoodItem(item, updatedItem);
      setState(() => items[index] = updatedItem);
    }
  }
}

class FoodItemDialog extends StatefulWidget {
  final FoodItem? originalItem;
  const FoodItemDialog({this.originalItem});

  @override
  _FoodItemDialogState createState() => _FoodItemDialogState();
}

class _FoodItemDialogState extends State<FoodItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  String _unit = 'Gramm';

  TextButton _buildDialogButton(String label, VoidCallback onPressed) =>
      TextButton(child: Text(label), onPressed: onPressed);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.originalItem?.name);
    _amountController =
        TextEditingController(text: widget.originalItem?.amount.toString());
    if (widget.originalItem != null) _unit = widget.originalItem!.unit;
  }

  @override
  Widget build(BuildContext context) {
    final unitOptions = ['Gramm', 'Kilogramm', 'Milliliter', 'Liter', 'Stück'];
    return AlertDialog(
      title: Text("Essen hinzufügen"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: "Name"),
          ),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(labelText: "Menge"),
            keyboardType: TextInputType.number,
          ),
          DropdownButton<String>(
            value: _unit,
            hint: Text("Einheit"),
            onChanged: (newValue) => setState(() => _unit = newValue!),
            items: unitOptions
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
          ),
        ],
      ),
      actions: [
        _buildDialogButton("Abbrechen", () => Navigator.pop(context)),
        _buildDialogButton("Hinzufügen", _addOrUpdateItem),
      ],
    );
  }

  _addOrUpdateItem() {
    final item = FoodItem(
      name: _nameController.text,
      amount: double.tryParse(_amountController.text) ?? 0.0,
      unit: _unit,
    );
    Navigator.of(context).pop(item);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
