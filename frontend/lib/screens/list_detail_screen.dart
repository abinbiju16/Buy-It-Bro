import 'dart:async';
import 'package:flutter/material.dart';
import '../models/grocery_list.dart';
import '../models/list_item.dart';
import '../models/common_groceries.dart';
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
  Timer? _pollTimer;
  bool _isLiveSyncing = false;

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
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _silentPoll();
    });
  }

  Future<void> _silentPoll() async {
    if (!mounted) return;
    try {
      final updated = await widget.api.getList(_currentList.id);
      if (mounted) {
        setState(() {
          _currentList = updated;
          _isLiveSyncing = true;
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _isLiveSyncing = false);
        });
      }
    } catch (_) {}
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

  Future<void> _adjustQuantity(ListItem item, double delta) async {
    final newQty = item.quantity + delta;
    if (newQty <= 0) return;

    final oldQty = item.quantity;
    setState(() {
      item.quantity = newQty;
    });

    try {
      final updated = await widget.api.updateItemDetails(
        listId: _currentList.id,
        itemId: item.id,
        quantity: newQty,
        expectedVersion: item.version,
      );
      setState(() {
        item.version = updated.version;
      });
    } catch (e) {
      setState(() {
        item.quantity = oldQty;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update quantity: $e')),
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

  Future<void> _quickAddItem(PredefinedGroceryItem preItem) async {
    // Check if item already exists
    final existingIndex = _currentList.items.indexWhere(
      (i) => i.name.trim().toLowerCase() == preItem.name.trim().toLowerCase(),
    );

    if (existingIndex != -1) {
      // Item already in list -> increment its quantity!
      final existing = _currentList.items[existingIndex];
      await _adjustQuantity(existing, preItem.defaultQuantity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1400),
            content: Text(
              '${preItem.emoji} ${existing.name} increased to ${existing.quantity.toString().replaceAll(RegExp(r'\.0$'), '')} ${existing.unit}!',
            ),
          ),
        );
      }
      return;
    }

    // Add new item
    try {
      final newItem = await widget.api.addItem(
        listId: _currentList.id,
        name: preItem.name,
        quantity: preItem.defaultQuantity,
        unit: preItem.defaultUnit,
      );
      if (mounted) {
        setState(() {
          _currentList.items.add(newItem);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1200),
            content: Text('Added ${preItem.emoji} ${preItem.name} (${preItem.defaultQuantity.toString().replaceAll(RegExp(r'\.0$'), '')} ${preItem.defaultUnit})'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    }
  }

  void _showEditItemDialog(ListItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl = TextEditingController(
      text: item.quantity.toString().replaceAll(RegExp(r'\.0$'), ''),
    );
    final noteCtrl = TextEditingController(text: item.note ?? '');
    String selectedUnit = item.unit;

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
                        'Edit Grocery Item',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      labelText: 'Optional Note',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          label: const Text('Delete', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deleteItem(item);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) return;
                            final qty = double.tryParse(qtyCtrl.text.trim()) ?? item.quantity;
                            final note = noteCtrl.text.trim();

                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(ctx);
                            try {
                              final updated = await widget.api.updateItemDetails(
                                listId: _currentList.id,
                                itemId: item.id,
                                name: name,
                                quantity: qty,
                                unit: selectedUnit,
                                note: note,
                                expectedVersion: item.version,
                              );
                              if (mounted) {
                                setState(() {
                                  item.name = updated.name;
                                  item.quantity = updated.quantity;
                                  item.unit = updated.unit;
                                  item.note = updated.note;
                                  item.version = updated.version;
                                });
                              }
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Failed to update item: $e')),
                              );
                            }
                          },
                          child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddItemDialog({PredefinedGroceryItem? initialItem}) {
    final nameCtrl = TextEditingController(text: initialItem?.name ?? '');
    final qtyCtrl = TextEditingController(
      text: initialItem != null
          ? initialItem.defaultQuantity.toString().replaceAll(RegExp(r'\.0$'), '')
          : '1',
    );
    final noteCtrl = TextEditingController();
    String selectedUnit = initialItem?.defaultUnit ?? 'pieces';

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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'POPULAR SUGGESTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: CommonGroceries.items.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final g = CommonGroceries.items[index];
                        return ActionChip(
                          avatar: Text(g.emoji),
                          label: Text(g.name),
                          backgroundColor: Colors.grey.shade100,
                          onPressed: () {
                            setModalState(() {
                              nameCtrl.text = g.name;
                              qtyCtrl.text = g.defaultQuantity.toString().replaceAll(RegExp(r'\.0$'), '');
                              selectedUnit = g.defaultUnit;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    autofocus: initialItem == null,
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      hintText: 'e.g. Milk, Rice, Coffee',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      labelText: 'Optional Note (brand, type, etc.)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
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
                    child: const Text('Add to List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
            Row(
              children: [
                Text(
                  _currentList.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (_isLiveSyncing) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                Text(
                  _currentList.isShared ? 'Shared Group List' : 'Personal List',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onPrimaryContainer.withAlpha(204),
                  ),
                ),
                if (_currentList.isShared) ...[
                  const SizedBox(width: 6),
                  Text(
                    '• Live Sync On (3s)',
                    style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
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
        onPressed: () => _showAddItemDialog(),
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
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                        Text(
                          '${purchased.length} / $total items',
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
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

            // Predefined Quick Add Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QUICK ADD MOST BOUGHT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'Tap to add or increase',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: CommonGroceries.items.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = CommonGroceries.items[index];
                      return ActionChip(
                        avatar: Text(item.emoji),
                        label: Text(
                          '${item.name} (+${item.defaultQuantity.toString().replaceAll(RegExp(r'\.0$'), '')} ${item.defaultUnit})',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () => _quickAddItem(item),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // To Buy Section
            if (unpurchased.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'TO BUY (${unpurchased.length}) — TAP ITEM TO EDIT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
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
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              ...purchased.map((item) => _buildItemTile(item, theme)),
            ],

            if (_currentList.items.isEmpty && !_loading) ...[
              const SizedBox(height: 36),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'This list is empty!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap a quick item above or "+ Add Item" below.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(ListItem item, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isChecked ? Colors.grey.shade200 : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showEditItemDialog(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // Checkbox
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: item.isChecked,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  activeColor: Colors.green.shade600,
                  onChanged: (val) => _toggleItem(item),
                ),
              ),
              const SizedBox(width: 6),

              // Item Name & Note
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: item.isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                        color: item.isChecked ? Colors.grey.shade400 : const Color(0xFF0F172A),
                      ),
                    ),
                    if (item.note != null && item.note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.note!,
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ),

              // Interactive Quantity Stepper: [-]  qty unit  [+]
              if (!item.isChecked)
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _adjustQuantity(item, -1),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.remove, size: 16, color: theme.colorScheme.primary),
                        ),
                      ),
                      // Quantity Text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '${item.quantity.toString().replaceAll(RegExp(r'\.0$'), '')} ${item.unit}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      // Plus
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _adjustQuantity(item, 1),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.quantity.toString().replaceAll(RegExp(r'\.0$'), '')} ${item.unit}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                  ),
                ),

              const SizedBox(width: 4),
              // Edit arrow hint
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade400),
                onPressed: () => _showEditItemDialog(item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
