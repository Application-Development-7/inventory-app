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
  List<MapEntry<String, int>> _categoryStocks = [];
  String? _categoryStockError;
  String? _selectedTransactionCategory;
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
            Expanded(
              child: Text(
                _index == 0
                    ? 'Overview'
                    : _index == 1
                    ? 'Products'
                    : _index == 2
                    ? 'Low stock'
                    : 'Trends & forecast',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
    final filteredRecent = recent.where((transaction) {
      if (!_isOnSelectedDate(transaction)) return false;
      if (_selectedTransactionCategory == null) return true;
      return _transactionCategory(transaction) == _selectedTransactionCategory;
    }).toList();

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _welcomeCard(),
          const SizedBox(height: 18),
          _statsRow(),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildStockByCategorySection()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildLowStockSection(low)),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStockByCategorySection(),
                  const SizedBox(height: 12),
                  _buildLowStockSection(low),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          _buildRecentTransactionsSection(filteredRecent),
        ],
      ),
    );
  }

  Widget _welcomeCard() {
    final username = context.read<AuthService>().username;
    return Container(
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
            'Welcome${username == null ? '' : ', $username'}',
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
    );
  }

  Widget _statsRow() {
    final stats = _data!['stats'];
    return Row(
      children: [
        _statCard(
          'Products',
          '${stats['total_products']}',
          Icons.inventory_2_rounded,
          const Color(0xFF087E76),
        ),
        const SizedBox(width: 8),
        _statCard(
          'Total stock',
          '${stats['total_stock']}',
          Icons.widgets_rounded,
          const Color(0xFF3977C5),
        ),
        const SizedBox(width: 8),
        _statCard(
          'Low stock',
          '${stats['low_stock_count']}',
          Icons.priority_high_rounded,
          const Color(0xFFE28B43),
        ),
      ],
    );
  }

  Widget _buildStockByCategorySection() {
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
                style: const TextStyle(color: Color(0xFFB53F48)),
              )
            : _categoryStocks.isEmpty
            ? const Text(
                'No category stock to show.',
                style: TextStyle(color: Color(0xFF71818A)),
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
                              style: const TextStyle(
                                color: Color(0xFF172B3A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${category.value}',
                            style: const TextStyle(
                              color: Color(0xFF71818A),
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
                          backgroundColor: const Color(0xFFE6EFEC),
                          color: const Color(0xFF378D78),
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
    return _dashboardSummaryCard(
      title: 'Needs Attention',
      subtitle: 'Low-stock products',
      child: SizedBox(
        height: 250,
        child: low.isEmpty
            ? const Center(
                child: Text(
                  'All stocked up.',
                  style: TextStyle(color: Color(0xFF71818A)),
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
                          color: const Color(0xFFFFF1E3),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFE28B43),
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
                              style: const TextStyle(
                                color: Color(0xFF172B3A),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product['quantity']} left · min ${product['min_stock']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF71818A),
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
    required Widget child,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8EA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF172B3A),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF71818A), fontSize: 11),
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
    final isIn = transaction['type'] == 'IN';
    final color = isIn ? const Color(0xFF25865B) : const Color(0xFFD65C54);
    final quantity = transaction['quantity']?.toString() ?? '0';

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8EA)),
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
                      color: const Color(0xFF172B3A),
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
                      color: const Color(0xFF84939A),
                      fontSize: compact ? 10 : 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9AABB0),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8EA)),
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
