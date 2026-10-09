import 'package:flutter/material.dart';
import '../models/grocery_list.dart';
import '../services/api_service.dart';
import 'list_detail_screen.dart';

class PersonalListsTab extends StatefulWidget {
  final ApiService api;

  const PersonalListsTab({super.key, required this.api});

  @override
  State<PersonalListsTab> createState() => _PersonalListsTabState();
}

class _PersonalListsTabState extends State<PersonalListsTab> {
  List<GroceryList> _lists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() => _loading = true);
    try {
      final fetched = await widget.api.getMyLists();
      if (mounted) {
        setState(() => _lists = fetched);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load private lists: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Private List'),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'List Name (e.g. Weekend Snacks)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final created = await widget.api.createPersonalList(title);
                setState(() => _lists.insert(0, created));
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ListDetailScreen(list: created, api: widget.api),
                    ),
                  ).then((_) => _loadLists());
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating list: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New List'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadLists,
        child: _lists.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checklist_rtl_rounded,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No private lists yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create a private list for your solo shopping trips.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _lists.length + 1,
                itemBuilder: (context, index) {
                  if (index == _lists.length) {
                    return const SizedBox(height: 80);
                  }
                  final list = _lists[index];
                  final total = list.itemCount;
                  final checked = list.checkedCount;
                  final progress = total > 0 ? (checked / total) : 0.0;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ListDetailScreen(list: list, api: widget.api),
                          ),
                        ).then((_) => _loadLists());
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    list.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Icon(Icons.lock_outline,
                                    size: 16, color: Colors.grey.shade400),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              total == 0
                                  ? '0 items'
                                  : '$checked of $total items completed',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress == 1.0
                                      ? Colors.green
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
