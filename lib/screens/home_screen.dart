import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/theme_provider.dart';
import 'products_screen.dart';
import 'low_stock_screen.dart';
import 'trends_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _data;
  int _index = 0;
  bool _loading = true;
  DateTime? _selectedTransactionDate;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _refreshDashboard() => _loadDashboard();

  Future<void> _selectTransactionDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedTransactionDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    if (selected != null && mounted) {
      setState(() => _selectedTransactionDate = selected);
    }
  }

  bool _isOnSelectedDate(Map<String, dynamic> transaction) {
    final selected = _selectedTransactionDate;
    if (selected == null) return true;
    final createdAt = DateTime.tryParse(
      transaction['created_at']?.toString() ?? '',
    );
    return createdAt != null &&
        createdAt.year == selected.year &&
        createdAt.month == selected.month &&
        createdAt.day == selected.day;
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final data = await context.read<ApiService>().get('/dashboard');
      if (mounted) {
        setState(() => _data = data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final themeProvider = context.watch<ThemeProvider>();
    final pages = [
      _dashboardView(),
      const ProductsScreen(),
      const LowStockScreen(),
      const TrendsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF087E76).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: Color(0xFF087E76),
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Text(
              _index == 0
                  ? 'Overview'
                  : _index == 1
                  ? 'Products'
                  : _index == 2
                  ? 'Low stock'
                  : 'Trends & forecast',
            ),
          ],
        ),
        actions: [
          if (_index == 0)
            IconButton(
              tooltip: 'Refresh dashboard',
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refreshDashboard,
            ),
          IconButton(
            tooltip: themeProvider.isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
          const SizedBox(width: 6),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout ${auth.username ?? ""}',
            onPressed: () => auth.logout(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber),
            label: 'Low Stock',
          ),
          NavigationDestination(icon: Icon(Icons.trending_up), label: 'Trends'),
        ],
      ),
    );
  }

  Widget _dashboardView() {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_data == null) {
      return Center(
        child: FilledButton.icon(
          onPressed: _loadDashboard,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    final low = (_data!['low_stock_products'] as List)
        .cast<Map<String, dynamic>>();
    final recent = (_data!['recent_transactions'] as List)
        .cast<Map<String, dynamic>>();
    final filteredRecent = recent.where(_isOnSelectedDate).toList();
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF087E76), Color(0xFF075B63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR STORE AT A GLANCE',
                  style: TextStyle(
                    color: Color(0xFFC4F2E8),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Welcome${context.read<AuthService>().username == null ? '' : ', ${context.read<AuthService>().username}'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Here’s what’s happening with your inventory today.',
                  style: TextStyle(color: Color(0xFFD7EEEA), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _statCard(
                'Products',
                '${_data!['stats']['total_products']}',
                Icons.inventory_2_rounded,
                const Color(0xFF087E76),
              ),
              const SizedBox(width: 10),
              _statCard(
                'Units in stock',
                '${_data!['stats']['total_stock']}',
                Icons.widgets_rounded,
                const Color(0xFF3977C5),
              ),
              const SizedBox(width: 10),
              _statCard(
                'Need attention',
                '${_data!['stats']['low_stock_count']}',
                Icons.priority_high_rounded,
                const Color(0xFFE28B43),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _sectionTitle('Needs attention', 'Low-stock products'),
          const SizedBox(height: 12),
          if (low.isEmpty)
            _emptyCard(
              Icons.check_circle_outline_rounded,
              'Looking good!',
              'All products are sufficiently stocked.',
            )
          else
            ...low.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1E3),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE28B43),
                      ),
                    ),
                    title: Text(
                      p['name'],
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${p['quantity']} left · minimum ${p['min_stock']}',
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          _sectionTitle('Latest activity', 'Recent transactions'),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _selectTransactionDate,
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text(
                  _selectedTransactionDate == null
                      ? 'Filter by date'
                      : _formatDate(_selectedTransactionDate!),
                ),
              ),
              if (_selectedTransactionDate != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _selectedTransactionDate = null),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (filteredRecent.isEmpty)
            _emptyCard(
              Icons.receipt_long_rounded,
              _selectedTransactionDate == null
                  ? 'No activity yet'
                  : 'No transactions on this date',
              _selectedTransactionDate == null
                  ? 'Stock movements will show up here.'
                  : 'Choose another date or clear the filter to see all recent transactions.',
            )
          else
            Card(
              child: Column(
                children: filteredRecent.asMap().entries.map((entry) {
                  final t = entry.value;
                  final isIn = t['type'] == 'IN';
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isIn
                                ? const Color(0xFFE5F5EE)
                                : const Color(0xFFFFECEA),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            isIn
                                ? Icons.south_west_rounded
                                : Icons.north_east_rounded,
                            color: isIn
                                ? const Color(0xFF25865B)
                                : const Color(0xFFD65C54),
                          ),
                        ),
                        title: Text(
                          '${t['product_name']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(t['created_at']?.toString() ?? ''),
                        trailing: Text(
                          '${isIn ? '+' : '-'}${t['quantity']}',
                          style: TextStyle(
                            color: isIn
                                ? const Color(0xFF25865B)
                                : const Color(0xFFD65C54),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (entry.key != filteredRecent.length - 1)
                        const Divider(height: 1, indent: 72),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(height: 13),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String eyebrow, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF087E76),
            letterSpacing: 1,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(IconData icon, String title, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF087E76), size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
