import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'personal_lists_tab.dart';
import 'groups_tab.dart';

class DashboardScreen extends StatefulWidget {
  final AuthService authService;

  const DashboardScreen({super.key, required this.authService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late final ApiService _api;

  @override
  void initState() {
    super.initState();
    _api = ApiService(token: widget.authService.token ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.shopping_bag_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BuyItBro',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  user != null ? 'Hi, ${user.displayName}' : 'My Groceries',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Sign Out'),
                  content:
                      const Text('Are you sure you want to sign out of BuyItBro?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.authService.logout();
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          PersonalListsTab(api: _api),
          GroupsTab(api: _api),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'My Lists',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Groups',
          ),
        ],
      ),
    );
  }
}
