import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../calendar/presentation/screens/calendar_body.dart';
import '../../../injection_log/presentation/screens/quick_log_body.dart';

/// Main app shell with 5-tab bottom navigation.
///
/// Tab layout (per §5 of SPEC):
///   0 — Calendar  (placeholder, FAB navigates to Log tab)
///   1 — Log       (Quick Log form)
///   2 — Weight    (placeholder)
///   3 — Health    (placeholder)
///   4 — Profile   (placeholder)
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  static const _titles = [
    'Today',
    'Log Injection',
    'Weight',
    'Health',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentTab])),
      body: IndexedStack(
        index: _currentTab,
        children: const [
          CalendarBody(),
          QuickLogBody(),
          _PlaceholderTab(icon: Icons.monitor_weight_outlined, label: 'Weight'),
          _PlaceholderTab(icon: Icons.favorite_border, label: 'Health'),
          _PlaceholderTab(icon: Icons.person_outline, label: 'Profile'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.amber.withAlpha(51),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: AppTheme.amber),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle, color: AppTheme.amber),
            label: 'Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight, color: AppTheme.amber),
            label: 'Weight',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: AppTheme.amber),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.amber),
            label: 'Profile',
          ),
        ],
      ),
      // FAB on Calendar tab — taps to Log tab for quick access.
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              onPressed: () => setState(() => _currentTab = 1),
              backgroundColor: AppTheme.amber,
              foregroundColor: const Color(0xFF1A1714),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppTheme.onSurface.withAlpha(76)),
          const SizedBox(height: 12),
          Text(
            '$label — coming soon',
            style: TextStyle(
              color: AppTheme.onSurface.withAlpha(128),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
