import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/api_service.dart';
import 'group_detail_screen.dart';

class GroupsTab extends StatefulWidget {
  final ApiService api;

  const GroupsTab({super.key, required this.api});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  List<Group> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    try {
      final fetched = await widget.api.getGroups();
      if (mounted) {
        setState(() => _groups = fetched);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load groups: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateGroupDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create New Group'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Group Name (e.g. Our Home, Flat 402)',
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
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final created = await widget.api.createGroup(name);
                setState(() => _groups.insert(0, created));
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GroupDetailScreen(group: created, api: widget.api),
                    ),
                  ).then((_) => _loadGroups());
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create group: $e')),
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

  void _showJoinGroupDialog() {
    final tokenCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Join Group with Invite Code'),
        content: TextField(
          controller: tokenCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Paste Invite Token',
            hintText: 'e.g. GIlcra4uD783...',
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
              final token = tokenCtrl.text.trim();
              if (token.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final joined = await widget.api.acceptInvitation(token);
                _loadGroups();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Joined "${joined.name}"!')),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GroupDetailScreen(group: joined, api: widget.api),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to join: $e')),
                  );
                }
              }
            },
            child: const Text('Join'),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join_group_btn',
            onPressed: _showJoinGroupDialog,
            backgroundColor: Colors.white,
            foregroundColor: theme.colorScheme.primary,
            tooltip: 'Join with Code',
            child: const Icon(Icons.key),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'new_group_btn',
            onPressed: _showCreateGroupDialog,
            icon: const Icon(Icons.group_add),
            label: const Text('New Group'),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroups,
        child: _groups.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No groups joined yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create a group for your home or join one using an invite code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.key),
                          label: const Text('Enter Invite Code'),
                          onPressed: _showJoinGroupDialog,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _groups.length + 1,
                itemBuilder: (context, index) {
                  if (index == _groups.length) {
                    return const SizedBox(height: 90);
                  }
                  final group = _groups[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            theme.colorScheme.secondary.withAlpha(30),
                        child: Icon(Icons.group,
                            color: theme.colorScheme.secondary, size: 26),
                      ),
                      title: Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.people_alt_outlined,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text('${group.memberCount} members',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade600)),
                            const SizedBox(width: 16),
                            Icon(Icons.format_list_bulleted,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text('${group.listCount} shared lists',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(
                                group: group, api: widget.api),
                          ),
                        ).then((_) => _loadGroups());
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
