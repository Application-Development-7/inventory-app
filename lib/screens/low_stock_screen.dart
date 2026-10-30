import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import 'product_form_screen.dart';
import 'stock_transaction_screen.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});
  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  static const _allCategories = 'All categories';

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _selectedCategory = _allCategories;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await context.read<ApiService>().get('/products/low-stock');
      if (mounted) {
        final items = (data as List).cast<Map<String, dynamic>>();
        final categories = items.map(_categoryName).toSet();
        setState(() {
          _items = items;
          if (!categories.contains(_selectedCategory)) {
            _selectedCategory = _allCategories;
          }
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _categories {
    final categories = _items.map(_categoryName).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return categories;
  }

  List<Map<String, dynamic>> get _filteredItems => _items.where((item) {
    final name = item['name']?.toString().toLowerCase() ?? '';
    final sku = item['sku']?.toString().toLowerCase() ?? '';
    final query = _search.toLowerCase();
    final matchesSearch = name.contains(query) || sku.contains(query);
    final matchesCategory =
        _selectedCategory == _allCategories ||
        _categoryName(item) == _selectedCategory;
    return matchesSearch && matchesCategory;
  }).toList();

  String _categoryName(Map<String, dynamic> item) {
    final category = item['category_name']?.toString().trim();
    return category == null || category.isEmpty ? 'Uncategorized' : category;
  }

  int _intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredItems = _filteredItems;
    final categories = [_allCategories, ..._categories];

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final margin = constraints.maxWidth >= 800 ? 32.0 : 20.0;
            return Padding(
              padding: EdgeInsets.all(margin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Low Stock',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Review items that need restocking',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${filteredItems.length} need attention',
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildActionBar(categories),
                  const SizedBox(height: 18),
                  Expanded(
                    child: _loading && _items.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null && _items.isEmpty
                        ? _buildErrorCard()
                        : _items.isEmpty
                        ? _buildEmptyCard()
                        : filteredItems.isEmpty
                        ? _buildNoMatchesCard()
                        : _isGridView
                        ? RefreshIndicator(
                            onRefresh: _load,
                            child: GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 20),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 350,
                                    crossAxisSpacing: 11,
                                    mainAxisSpacing: 11,
                                    mainAxisExtent: 220,
                                  ),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) =>
                                  _buildLowStockCard(
                                    filteredItems[index],
                                    isGrid: true,
                                  ),
                            ),
                          )
                        : _buildTable(filteredItems),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionBar(List<String> categories) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Search low stock products...',
            isDense: true,
          ),
          onChanged: (value) => setState(() => _search = value),
        );
        final categoryDropdown = DropdownButtonFormField<String>(
          initialValue: categories.contains(_selectedCategory)
              ? _selectedCategory
              : _allCategories,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Category',
            isDense: true,
          ),
          items: categories
              .map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (category) {
            if (category != null) {
              setState(() => _selectedCategory = category);
            }
          },
        );
        final toggle = IconButton(
          tooltip: _isGridView ? 'Show as table' : 'Show as grid',
          onPressed: () => setState(() => _isGridView = !_isGridView),
          icon: Icon(
            _isGridView ? Icons.table_rows_rounded : Icons.grid_view_rounded,
          ),
        );

        if (constraints.maxWidth >= 760) {
          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 10),
              SizedBox(width: 210, child: categoryDropdown),
              const SizedBox(width: 8),
              toggle,
            ],
          );
        }

        return Column(
          children: [
            search,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: categoryDropdown),
                const SizedBox(width: 8),
                toggle,
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 38),
            const SizedBox(height: 10),
            Text(
              'Could not load low-stock items',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'All stocked up!',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'All products are above their minimum stock levels.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoMatchesCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No low-stock products match your search or category.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(760.0, constraints.maxWidth).toDouble();
        return RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  _tableHeader(),
                  Expanded(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) => _tableRow(items[index]),
                    ),
                  ),
                  _tableFooter(items.length),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tableHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 4, child: _TableHeaderLabel('PRODUCT')),
          Expanded(flex: 2, child: _TableHeaderLabel('CATEGORY')),
          Expanded(flex: 2, child: _TableHeaderLabel('CURRENT STOCK')),
          Expanded(flex: 2, child: _TableHeaderLabel('MINIMUM')),
          Expanded(flex: 2, child: _TableHeaderLabel('STATUS')),
          SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> item) {
    final colorScheme = Theme.of(context).colorScheme;
    final quantity = _intValue(item['quantity']);
    final isOutOfStock = quantity <= 0;
    final statusColor = isOutOfStock ? colorScheme.error : colorScheme.tertiary;
    final sku = item['sku']?.toString().trim();

    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.onTertiaryContainer,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name']?.toString() ?? 'Unnamed product',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sku == null || sku.isEmpty ? 'SKU not set' : sku,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _categoryName(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$quantity',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${_intValue(item['min_stock'])}',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOutOfStock ? 'Out of stock' : 'Low stock',
                  maxLines: 1,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 44, child: _itemActions(item)),
        ],
      ),
    );
  }

  Widget _tableFooter(int displayedCount) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $displayedCount of ${_items.length} low-stock products',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          const IconButton(
            tooltip: 'Previous page',
            onPressed: null,
            icon: Icon(Icons.chevron_left_rounded),
          ),
          Text(
            '1',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const IconButton(
            tooltip: 'Next page',
            onPressed: null,
            icon: Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _itemActions(Map<String, dynamic> item) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      tooltip: 'Product actions',
      onSelected: (value) async {
        if (value == 'edit') {
          await showDialog<void>(
            context: context,
            builder: (_) => ProductFormScreen(product: item),
          );
          if (mounted) _load();
        } else if (value == 'in' || value == 'out') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StockTransactionScreen(
                product: item,
                type: value == 'in' ? 'IN' : 'OUT',
              ),
            ),
          );
          if (mounted) _load();
        } else if (value == 'delete') {
          _delete(_intValue(item['id']));
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit product')),
        const PopupMenuItem(value: 'in', child: Text('Stock in')),
        const PopupMenuItem(value: 'out', child: Text('Stock out')),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'Delete',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }

  Future<void> _delete(int id) async {
    final api = context.read<ApiService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await api.delete('/products/$id');
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _buildLowStockCard(Map<String, dynamic> item, {bool isGrid = false}) {
    final quantity = _intValue(item['quantity']);
    final minimum = _intValue(item['min_stock']);
    final progress = minimum <= 0 ? 0.0 : (quantity / minimum).clamp(0.0, 1.0);
    final colorScheme = Theme.of(context).colorScheme;
    final isOutOfStock = quantity <= 0;
    final statusColor = isOutOfStock ? colorScheme.error : colorScheme.tertiary;

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isGrid ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isGrid
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isGrid ? 38 : 45,
                  height: isGrid ? 38 : 45,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.onTertiaryContainer,
                    size: isGrid ? 22 : 25,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name']?.toString() ?? 'Unnamed product',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: isGrid ? 13 : 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['sku']?.toString() ?? 'SKU not set',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isGrid) ...[
                  _statusBadge(isOutOfStock, statusColor),
                  const SizedBox(width: 6),
                ],
                _itemActions(item),
              ],
            ),
            SizedBox(height: isGrid ? 8 : 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _stockValue(
                    'CURRENT STOCK',
                    '$quantity',
                    statusColor,
                    isGrid,
                  ),
                ),
                Expanded(
                  child: _stockValue(
                    'MINIMUM STOCK',
                    '$minimum',
                    colorScheme.onSurfaceVariant,
                    isGrid,
                  ),
                ),
                if (isGrid) _statusBadge(isOutOfStock, statusColor),
              ],
            ),
            SizedBox(height: isGrid ? 7 : 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: isGrid ? 5 : 7,
                backgroundColor: colorScheme.errorContainer,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(bool isOutOfStock, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOutOfStock ? 'Out of stock' : 'Low stock',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _stockValue(String label, String value, Color color, bool isGrid) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: isGrid ? 8 : 9,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: isGrid ? 17 : 23,
          ),
        ),
      ],
    );
  }
}

class _TableHeaderLabel extends StatelessWidget {
  final String label;

  const _TableHeaderLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 10,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
