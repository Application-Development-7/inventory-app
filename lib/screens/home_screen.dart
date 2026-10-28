import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/theme_provider.dart';
import 'product_form_screen.dart';
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
  List<MapEntry<String, int>> _categoryStocks = [];
  String? _categoryStockError;
  String? _selectedTransactionCategory;
  int _index = 0;
  bool _loading = true;
  bool _hideInventoryValue = false;
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

  String _formatTransactionDate(dynamic value) {
    final rawDate = value?.toString() ?? '';
    final date = DateTime.tryParse(rawDate);
    if (date == null) return rawDate;

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} · '
        '$hour:$minute $period';
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    final api = context.read<ApiService>();
    try {
      final data = await api.get('/dashboard');
      if (mounted) {
        setState(() => _data = data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    try {
      final products = (await api.get('/products') as List)
          .cast<Map<String, dynamic>>();
      final stockByCategory = <String, int>{};
      for (final product in products) {
        final rawCategory = product['category_name']?.toString().trim();
        final category = rawCategory == null || rawCategory.isEmpty
            ? 'Uncategorized'
            : rawCategory;
        final rawQuantity = product['quantity'];
        final quantity = rawQuantity is num
            ? rawQuantity.toInt()
            : int.tryParse(rawQuantity?.toString() ?? '') ?? 0;
        stockByCategory.update(
          category,
          (total) => total + quantity,
          ifAbsent: () => quantity,
        );
      }
      final categoryStocks = stockByCategory.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
      if (mounted) {
        setState(() {
          _categoryStocks = categoryStocks;
          _categoryStockError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoryStockError = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final pages = [
      _dashboardView(),
      const ProductsScreen(),
      const LowStockScreen(),
      const TrendsScreen(),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (isDesktop)
                  _desktopSidebar(colorScheme, auth.username ?? 'Admin'),
                Expanded(
                  child: Column(
                    children: [
                      _topHeader(
                        themeProvider,
                        auth.username ?? 'Admin',
                        showSearch: isDesktop,
                      ),
                      Expanded(child: pages[_index]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isDesktop
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_rounded),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.inventory_2_rounded),
                      label: 'Products',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.warning_amber_rounded),
                      label: 'Low Stock',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.trending_up_rounded),
                      label: 'Trends',
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _topHeader(
    ThemeProvider themeProvider,
    String username, {
    required bool showSearch,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: showSearch ? 520 : double.infinity,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search anything...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          if (_index == 0)
            IconButton(
              tooltip: 'Refresh dashboard',
              onPressed: _refreshDashboard,
              icon: const Icon(Icons.refresh_rounded),
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
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You are all caught up.')),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              username.isEmpty ? 'A' : username[0].toUpperCase(),
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopSidebar(ColorScheme colorScheme, String username) {
    final stats = _data?['stats'] as Map? ?? const {};
    final lowCount = _intValue(stats['low_stock_count']);
    final totalProducts = _intValue(stats['total_products']);
    final health = totalProducts == 0
        ? 0.0
        : ((totalProducts - lowCount) / totalProducts).clamp(0.0, 1.0);
    const destinations = [
      (Icons.dashboard_rounded, 'Dashboard'),
      (Icons.inventory_2_rounded, 'Products'),
      (Icons.warning_amber_rounded, 'Low Stock'),
      (Icons.trending_up_rounded, 'Trends'),
    ];

    return Container(
      width: 250,
      padding: const EdgeInsets.fromLTRB(17, 22, 17, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 30),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Stockwise',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'WORKSPACE',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < destinations.length; index++)
            _sidebarItem(
              icon: destinations[index].$1,
              label: destinations[index].$2,
              index: index,
              badge: index == 2 ? lowCount : null,
            ),
          const Spacer(),
          _inventoryHealthCard(colorScheme, health, lowCount),
          const SizedBox(height: 15),
          Divider(color: colorScheme.outlineVariant),
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  username.isEmpty ? 'A' : username[0].toUpperCase(),
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Administrator',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Log out',
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded, size: 19),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Are you sure you want to log out of your workspace?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthService>().logout();
    }
  }

  Widget _sidebarItem({
    required IconData icon,
    required String label,
    required int index,
    int? badge,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _index == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _index = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null && badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        color: colorScheme.onError,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inventoryHealthCard(
    ColorScheme colorScheme,
    double health,
    int lowCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_outline_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Inventory Health',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${(health * 100).round()}%',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: health,
              minHeight: 7,
              backgroundColor: colorScheme.outlineVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$lowCount items need attention',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  int _intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _currencyValue(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (amount == null || !amount.isFinite) return '—';

    final parts = amount.toStringAsFixed(2).split('.');
    final groupedWhole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '₱$groupedWhole.${parts.last}';
  }

  Widget _kpiCards(Map stats) {
    final totalProducts = _intValue(stats['total_products']);
    final stock = _intValue(stats['total_stock']);
    final lowCount = _intValue(stats['low_stock_count']);
    final inventoryValue = stats['inventory_value'];
    final valueText = _currencyValue(inventoryValue);
    final items = [
      (
        'Total Products',
        '$totalProducts',
        Icons.inventory_2_outlined,
        Theme.of(context).colorScheme.primary,
        'In catalog',
      ),
      (
        'Inventory Value',
        valueText,
        Icons.account_balance_wallet_outlined,
        Theme.of(context).colorScheme.secondary,
        inventoryValue == null ? 'Not provided by API' : 'Current value',
      ),
      (
        'Units in Stock',
        '$stock',
        Icons.widgets_outlined,
        Theme.of(context).colorScheme.tertiary,
        'Units available',
      ),
      (
        'Low Stock',
        '$lowCount',
        Icons.warning_amber_rounded,
        Theme.of(context).colorScheme.error,
        lowCount == 0 ? 'All stocked up' : 'Needs attention',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 580
            ? 2
            : 1;
        const spacing = 14.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: cardWidth,
                  child: _kpiCard(
                    item.$1,
                    item.$1 == 'Inventory Value' && _hideInventoryValue
                        ? '******'
                        : item.$2,
                    item.$3,
                    item.$4,
                    item.$5,
                    isInventoryValue: item.$1 == 'Inventory Value',
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _kpiCard(
    String title,
    String value,
    IconData icon,
    Color accent,
    String status, {
    bool isInventoryValue = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                if (isInventoryValue)
                  IconButton(
                    tooltip: _hideInventoryValue
                        ? 'Show inventory value'
                        : 'Hide inventory value',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(
                      () => _hideInventoryValue = !_hideInventoryValue,
                    ),
                    icon: Icon(
                      _hideInventoryValue
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: colorScheme.onSurfaceVariant,
                      size: 19,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockCategoryChartCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final values = _categoryStocks
        .map((entry) => entry.value.toDouble())
        .toList();
    final maxY = values.isEmpty
        ? 1.0
        : math.max(1.0, values.reduce(math.max) * 1.2);
    final maxX = math.max(1, _categoryStocks.length - 1).toDouble();

    return _dashboardSummaryCard(
      title: 'Stock by Category',
      subtitle: 'Current units on hand across your categories',
      trailing: PopupMenuButton<String>(
        tooltip: 'Chart period',
        onSelected: (value) {
          if (value == 'Last 6 months') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Historical category snapshots are not available yet.',
                ),
              ),
            );
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'Current stock', child: Text('Current stock')),
          PopupMenuItem(value: 'Last 6 months', child: Text('Last 6 months')),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current stock',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            ],
          ),
        ),
      ),
      child: SizedBox(
        height: 270,
        child: _categoryStockError != null
            ? Center(
                child: Text(
                  'Could not load category stock.',
                  style: TextStyle(color: colorScheme.error),
                ),
              )
            : _categoryStocks.isEmpty
            ? Center(
                child: Text(
                  'No category stock to show.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              )
            : LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxX,
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: _categoryStocks.length > 6
                            ? (_categoryStocks.length / 5).ceilToDouble()
                            : 1,
                        getTitlesWidget: (value, _) {
                          final index = value.round();
                          if (index < 0 ||
                              index >= _categoryStocks.length ||
                              (value - index).abs() > 0.1) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: 70,
                              child: Text(
                                _categoryStocks[index].key,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _categoryStocks.indexed
                          .map(
                            (entry) => FlSpot(
                              entry.$1.toDouble(),
                              entry.$2.value.toDouble(),
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _recentActivityCard(List<Map<String, dynamic>> transactions) {
    final colorScheme = Theme.of(context).colorScheme;
    return _dashboardSummaryCard(
      title: 'Recent Activity',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            tooltip: 'Filter by category',
            icon: const Icon(Icons.filter_list_rounded, size: 20),
            onSelected: (value) => setState(
              () => _selectedTransactionCategory = value == '__all__'
                  ? null
                  : value,
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: '__all__',
                child: Text('All categories'),
              ),
              ..._categoryStocks.map(
                (category) => PopupMenuItem(
                  value: category.key,
                  child: Text(category.key),
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Filter by date',
            onPressed: _selectTransactionDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedTransactionDate != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _selectedTransactionDate = null),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Clear date filter'),
              ),
            ),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No recent activity.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            for (final transaction in transactions.take(5))
              _activityRow(transaction),
        ],
      ),
    );
  }

  Widget _activityRow(Map<String, dynamic> transaction) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIn = transaction['type'] == 'IN';
    final accent = isIn ? colorScheme.primary : colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isIn ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['product_name']?.toString() ?? 'Inventory item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${isIn ? 'Stock in' : 'Stock out'} · '
                  '${transaction['quantity'] ?? 0} units',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _formatTransactionDate(transaction['created_at']),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topCategoriesCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final topCategories = [..._categoryStocks]
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalStock = _categoryStocks.fold<int>(
      0,
      (total, category) => total + category.value,
    );
    return _dashboardSummaryCard(
      title: 'Top Categories',
      subtitle: 'Stock distribution by category',
      child: topCategories.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Category stock is not available.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          : Column(
              children: topCategories.take(5).map((category) {
                final proportion = totalStock == 0
                    ? 0.0
                    : (category.value / totalStock).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.key,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${category.value} units',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: proportion,
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _alertCard(List<Map<String, dynamic>> low) {
    final colorScheme = Theme.of(context).colorScheme;
    return _dashboardSummaryCard(
      title: 'Items require your attention',
      subtitle: '${low.length} low-stock items',
      trailing: TextButton(
        onPressed: () => setState(() => _index = 2),
        child: const Text('View all'),
      ),
      child: low.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Everything is stocked up.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (final item in low.take(4))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            item['name']?.toString() ?? 'Inventory item',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${item['quantity'] ?? 0} left',
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
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
    final filteredRecent = recent.where((transaction) {
      if (!_isOnSelectedDate(transaction)) return false;
      if (_selectedTransactionCategory == null) return true;
      return _transactionCategory(transaction) == _selectedTransactionCategory;
    }).toList();
    final username = context.watch<AuthService>().username ?? 'admin';
    final stats = _data!['stats'] as Map? ?? const {};

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final margin = constraints.maxWidth >= 800 ? 32.0 : 20.0;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(margin),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning, $username',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Here is what is happening with your inventory today.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  FilledButton.icon(
                    onPressed: () async {
                      await showDialog<void>(
                        context: context,
                        builder: (_) => const ProductFormScreen(),
                      );
                      if (mounted) _loadDashboard();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _kpiCards(stats),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _stockCategoryChartCard()),
                        const SizedBox(width: 18),
                        Expanded(child: _recentActivityCard(filteredRecent)),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _stockCategoryChartCard(),
                      const SizedBox(height: 16),
                      _recentActivityCard(filteredRecent),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final categories = _topCategoriesCard();
                  final alerts = _alertCard(low);
                  if (constraints.maxWidth >= 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: categories),
                        const SizedBox(width: 18),
                        Expanded(child: alerts),
                      ],
                    );
                  }
                  return Column(
                    children: [categories, const SizedBox(height: 16), alerts],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _welcomeCard() {
    final username = context.read<AuthService>().username;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR STORE AT A GLANCE',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Welcome${username == null ? '' : ', $username'}',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Here’s what’s happening with your inventory today.',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    final colorScheme = Theme.of(context).colorScheme;
    final stats = _data!['stats'];
    return Row(
      children: [
        _statCard(
          'Products',
          '${stats['total_products']}',
          Icons.inventory_2_rounded,
          colorScheme.primary,
        ),
        const SizedBox(width: 8),
        _statCard(
          'Total stock',
          '${stats['total_stock']}',
          Icons.widgets_rounded,
          colorScheme.secondary,
        ),
        const SizedBox(width: 8),
        _statCard(
          'Low stock',
          '${stats['low_stock_count']}',
          Icons.priority_high_rounded,
          colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildStockByCategorySection() {
    final colorScheme = Theme.of(context).colorScheme;
    final totalStock = _categoryStocks.fold<int>(
      0,
      (total, category) => total + category.value,
    );

    return _dashboardSummaryCard(
      title: 'Stock by Category',
      child: SizedBox(
        height: 250,
        child: _categoryStockError != null
            ? Text(
                'Could not load category stock.',
                style: TextStyle(color: colorScheme.error),
              )
            : _categoryStocks.isEmpty
            ? Text(
                'No category stock to show.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              )
            : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _categoryStocks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, index) {
                  final category = _categoryStocks[index];
                  final proportion = totalStock <= 0
                      ? 0.0
                      : (category.value / totalStock).clamp(0.0, 1.0);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${category.value}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: proportion,
                          minHeight: 7,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildLowStockSection(List<Map<String, dynamic>> low) {
    final colorScheme = Theme.of(context).colorScheme;
    return _dashboardSummaryCard(
      title: 'Needs Attention',
      subtitle: 'Low-stock products',
      child: SizedBox(
        height: 250,
        child: low.isEmpty
            ? Center(
                child: Text(
                  'All stocked up.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: low.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final product = low[index];
                  return Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: colorScheme.onTertiaryContainer,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name']?.toString() ?? 'Inventory item',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product['quantity']} left · min ${product['min_stock']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _dashboardSummaryCard({
    required String title,
    String? subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(
    List<Map<String, dynamic>> filteredRecent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildRecentTransactionsHeader()),
            const SizedBox(width: 10),
            SizedBox(
              width: 165,
              child: DropdownButtonFormField<String?>(
                initialValue: _selectedTransactionCategory,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ..._categoryStocks.map(
                    (category) => DropdownMenuItem<String?>(
                      value: category.key,
                      child: Text(
                        category.key,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (category) =>
                    setState(() => _selectedTransactionCategory = category),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTransactionDateFilter(),
        const SizedBox(height: 10),
        ...filteredRecent.isEmpty
            ? [_buildNoTransactionsCard()]
            : filteredRecent.map(_buildTransactionCard),
      ],
    );
  }

  Widget _buildRecentTransactionsHeader() {
    return _sectionTitle('Latest activity', 'Recent transactions');
  }

  String _transactionCategory(Map<String, dynamic> transaction) {
    final category = transaction['category_name']?.toString().trim();
    return category == null || category.isEmpty ? 'Uncategorized' : category;
  }

  Widget _buildTransactionDateFilter() {
    return Row(
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
            onPressed: () => setState(() => _selectedTransactionDate = null),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Clear'),
          ),
        ],
      ],
    );
  }

  Widget _buildNoTransactionsCard() {
    return _emptyCard(
      Icons.receipt_long_rounded,
      _selectedTransactionDate == null
          ? 'No activity yet'
          : 'No transactions on this date',
      _selectedTransactionDate == null ? 'Stock movements will show up here.' : 'Choose another date or clear the filter to see all recent transactions.',
    );
  }

  Widget _buildTransactionCard(
    Map<String, dynamic> transaction, {
    bool compact = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIn = transaction['type'] == 'IN';
    final color = isIn ? colorScheme.primary : colorScheme.error;
    final quantity = transaction['quantity']?.toString() ?? '0';

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 8 : 11,
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 38 : 44,
              height: compact ? 38 : 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIn ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: color,
                size: compact ? 18 : 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction['product_name']?.toString() ?? 'Inventory item',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 13 : 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isIn ? 'Stock In' : 'Stock Out'} · '
                    '${isIn ? '+' : '-'}$quantity units',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 11 : 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTransactionDate(transaction['created_at']),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: compact ? 10 : 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
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
                    color: colorScheme.onSurface,
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
                  color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            color: colorScheme.primary,
            letterSpacing: 1,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(IconData icon, String title, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
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
