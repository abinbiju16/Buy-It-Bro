import 'package:flutter/material.dart';
import '../models/grocery_list.dart';
import '../models/list_item.dart';
import '../services/api_service.dart';

class ListDetailScreen extends StatefulWidget {
  final GroceryList list;
  final ApiService api;

  const ListDetailScreen({super.key, required this.list, required this.api});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  late GroceryList _currentList;
  bool _loading = false;

  final List<String> _commonUnits = [
    'pieces',
    'packets',
    'kg',
    'g',
    'litres',
    'ml',
    'bottles'
  ];

  @override
  void initState() {
    super.initState();
    _currentList = widget.list;
    _refreshList();
  }

  Future<void> _refreshList() async {
    setState(() => _loading = true);
    try {
      final updated = await widget.api.getList(_currentList.id);
      if (mounted) {
        setState(() {
          _currentList = updated;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh list: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleItem(ListItem item) async {
    final originalState = item.isChecked;
    // Optimistic UI update
    setState(() {
      item.isChecked = !item.isChecked;
    });

    try {
      final updated = await widget.api.toggleItemChecked(
        listId: _currentList.id,
        itemId: item.id,
        isChecked: item.isChecked,
        expectedVersion: item.version,
      );
      setState(() {
        item.version = updated.version;
      });
    } catch (e) {
      // Revert if failed
      setState(() {
        item.isChecked = originalState;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
        _refreshList();
      }
    }
  }

  Future<void> _deleteItem(ListItem item) async {
    try {
      await widget.api.deleteItem(_currentList.id, item.id);
      setState(() {
        _currentList.items.removeWhere((i) => i.id == item.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $e')),
        );
      }
    }
  }

  void _showAddItemDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final noteCtrl = TextEditingController();
    String selectedUnit = 'pieces';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Grocery Item',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Item Name (e.g. Milk, Rice)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedUnit,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _commonUnits.map((u) {
                            return DropdownMenuItem(value: u, child: Text(u));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedUnit = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Optional Note (e.g. Prefer Royal brand)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
                      final messenger = ScaffoldMessenger.of(context);

                      Navigator.pop(ctx);
                      try {
                        final newItem = await widget.api.addItem(
                          listId: _currentList.id,
                          name: name,
                          quantity: qty,
                          unit: selectedUnit,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                        );
                        if (mounted) {
                          setState(() {
                            _currentList.items.add(newItem);
                          });
                        }
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Failed to add item: $e')),
                        );
                      }
                    },
                    child: const Text(
                      'Add to List',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unpurchased = _currentList.items.where((i) => !i.isChecked).toList();
    final purchased = _currentList.items.where((i) => i.isChecked).toList();
    final total = _currentList.items.length;
    final progress = total > 0 ? (purchased.length / total) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentList.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              _currentList.isShared ? 'Shared Group List' : 'Personal List',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onPrimaryContainer.withAlpha(204),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshList,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshList,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Progress Overview Card
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shopping Progress',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '${purchased.length} / $total items',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress == 1.0 ? Colors.green : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // To Buy Section
            if (unpurchased.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'TO BUY (${unpurchased.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              ...unpurchased.map((item) => _buildItemTile(item, theme)),
            ],

            // Purchased Section
            if (purchased.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'COMPLETED (${purchased.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              ...purchased.map((item) => _buildItemTile(item, theme)),
            ],

            if (_currentList.items.isEmpty && !_loading) ...[
              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_basket_outlined,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'This list is empty!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "+ Add Item" below to start adding groceries.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 80), // Padding for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(ListItem item, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isChecked ? Colors.grey.shade200 : Colors.grey.shade300,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: item.isChecked,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            activeColor: Colors.green.shade600,
            onChanged: (val) => _toggleItem(item),
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: item.isChecked
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: item.isChecked ? Colors.grey.shade400 : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: item.isChecked
                    ? Colors.grey.shade100
                    : theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${item.quantity.toString().replaceAll(RegExp(r'\.0$'), '')} ${item.unit}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: item.isChecked
                      ? Colors.grey.shade500
                      : theme.colorScheme.primary,
                ),
              ),
            ),
            if (item.note != null && item.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Note: ${item.note}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.grey.shade400),
          onPressed: () => _deleteItem(item),
        ),
      ),
    );
  }
}
