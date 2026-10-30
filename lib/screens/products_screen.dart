import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import 'product_form_screen.dart';
import 'stock_transaction_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const _allCategories = 'All categories';
  static const _sortOptions = [
    'Default',
    'Stock: High to Low',
    'Stock: Low to High',
    'Price: High to Low',
    'Price: Low to High',
  ];

  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String _search = '';
  String _selectedCategory = _allCategories;
  String _selectedSort = 'Default';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await context.read<ApiService>().get('/products');
      if (mounted) {
        final products = (data as List).cast<Map<String, dynamic>>();
        final categories = products.map(_categoryName).toSet();
        setState(() {
          _products = products;
          if (!categories.contains(_selectedCategory)) {
            _selectedCategory = _allCategories;
          }
        });
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

  Future<void> _delete(int id) async {
    final api = context.read<ApiService>();
    final ok = await showDialog<bool>(
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
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
  }

  List<String> get _categories {
    final categories =
        _products.map((product) => _categoryName(product)).toSet().toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return categories;
  }

  String _categoryName(Map<String, dynamic> product) {
    final category = product['category_name']?.toString().trim();
    return category == null || category.isEmpty ? 'Uncategorized' : category;
  }

  int _intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> get _visibleProducts {
    final products = _products.where((product) {
      final name = product['name']?.toString().toLowerCase() ?? '';
      final sku = product['sku']?.toString().toLowerCase() ?? '';
      final query = _search.toLowerCase();
      final matchesSearch = name.contains(query) || sku.contains(query);
      final matchesCategory =
          _selectedCategory == _allCategories ||
          _categoryName(product) == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    switch (_selectedSort) {
      case 'Stock: High to Low':
        products.sort(
          (a, b) =>
              _intValue(b['quantity']).compareTo(_intValue(a['quantity'])),
        );
      case 'Stock: Low to High':
        products.sort(
          (a, b) =>
              _intValue(a['quantity']).compareTo(_intValue(b['quantity'])),
        );
      case 'Price: High to Low':
        products.sort(
          (a, b) =>
              _doubleValue(b['price']).compareTo(_doubleValue(a['price'])),
        );
      case 'Price: Low to High':
        products.sort(
          (a, b) =>
              _doubleValue(a['price']).compareTo(_doubleValue(b['price'])),
        );
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _visibleProducts;
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
                              'Products',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your inventory catalog',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildActionBar(categories),
                  const SizedBox(height: 18),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : filtered.isEmpty
                        ? _emptyProductsState(colorScheme)
                        : _isGridView
                        ? RefreshIndicator(
                            onRefresh: _load,
                            child: _buildGridView(filtered),
                          )
                        : _buildProductTable(filtered),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openAddProduct() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const ProductFormScreen(),
    );
    if (mounted) _load();
  }

  Widget _buildActionBar(List<String> categories) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Search products or SKU...',
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
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        final sortDropdown = DropdownButtonFormField<String>(
          initialValue: _selectedSort,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Sort by',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: _sortOptions
              .map(
                (option) => DropdownMenuItem(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (sort) {
            if (sort != null) setState(() => _selectedSort = sort);
          },
        );
        final toggle = IconButton.outlined(
          tooltip: _isGridView ? 'Show as table' : 'Show as grid',
          onPressed: () => setState(() => _isGridView = !_isGridView),
          icon: Icon(
            _isGridView ? Icons.table_rows_rounded : Icons.grid_view_rounded,
          ),
        );
        final addButton = FilledButton.icon(
          onPressed: _openAddProduct,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Product'),
        );

        if (constraints.maxWidth >= 940) {
          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 10),
              SizedBox(width: 170, child: categoryDropdown),
              const SizedBox(width: 10),
              SizedBox(width: 180, child: sortDropdown),
              const SizedBox(width: 8),
              toggle,
              const SizedBox(width: 8),
              addButton,
            ],
          );
        }

        return Column(
          children: [
            search,
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(width: 160, child: categoryDropdown),
                SizedBox(width: 180, child: sortDropdown),
                toggle,
                addButton,
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _emptyProductsState(ColorScheme colorScheme) {
    final noProducts = _search.isEmpty && _selectedCategory == _allCategories;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 60),
          Icon(
            noProducts ? Icons.inventory_2_outlined : Icons.search_off_rounded,
            size: 52,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 15),
          Text(
            noProducts ? 'Your catalog is ready' : 'No matching products',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            noProducts
                ? 'Add your first product to start tracking stock.'
                : 'Try changing your search or category.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTable(List<Map<String, dynamic>> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final tableWidth = compact
            ? math.max(620.0, constraints.maxWidth).toDouble()
            : constraints.maxWidth;
        return RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  _tableHeader(compact),
                  Expanded(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: products.length,
                      itemBuilder: (context, index) =>
                          _productTableRow(products[index], compact),
                    ),
                  ),
                  _tableFooter(products.length),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tableHeader(bool compact) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          const Expanded(flex: 5, child: _TableHeaderLabel('PRODUCT')),
          if (!compact)
            const Expanded(flex: 2, child: _TableHeaderLabel('CATEGORY')),
          const Expanded(flex: 2, child: _TableHeaderLabel('STOCK')),
          const Expanded(flex: 2, child: _TableHeaderLabel('STATUS')),
          if (!compact)
            const Expanded(flex: 2, child: _TableHeaderLabel('PRICE')),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _productTableRow(Map<String, dynamic> product, bool compact) {
    final colorScheme = Theme.of(context).colorScheme;
    final quantity = _intValue(product['quantity']);
    final minimum = _intValue(product['min_stock']);
    final status = quantity <= 0
        ? 'Out of stock'
        : quantity <= minimum
        ? 'Low stock'
        : 'In stock';
    final statusColor = status == 'Out of stock'
        ? colorScheme.error
        : status == 'Low stock'
        ? colorScheme.tertiary
        : colorScheme.primary;
    final sku = product['sku']?.toString().trim();

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
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name']?.toString() ?? 'Unnamed product',
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
          if (!compact)
            Expanded(
              flex: 2,
              child: Text(
                _categoryName(product),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          Expanded(
            flex: 2,
            child: Text(
              '$quantity units',
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
                  status,
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
          if (!compact)
            Expanded(
              flex: 2,
              child: Text(
                '₱${_doubleValue(product['price']).toStringAsFixed(2)}',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          SizedBox(width: 44, child: _productActions(product)),
        ],
      ),
    );
  }

  Widget _productActions(Map<String, dynamic> product) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      tooltip: 'Product actions',
      onSelected: (value) async {
        if (value == 'edit') {
          await showDialog<void>(
            context: context,
            builder: (_) => ProductFormScreen(product: product),
          );
          if (mounted) _load();
        } else if (value == 'in' || value == 'out') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StockTransactionScreen(
                product: product,
                type: value == 'in' ? 'IN' : 'OUT',
              ),
            ),
          );
          if (mounted) _load();
        } else if (value == 'delete') {
          _delete(_intValue(product['id']));
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
              'Showing $displayedCount of ${_products.length} products',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(onPressed: null, child: const Text('Previous')),
          const SizedBox(width: 4),
          FilledButton.tonal(onPressed: null, child: const Text('1')),
          const SizedBox(width: 4),
          TextButton(onPressed: null, child: const Text('2')),
          const SizedBox(width: 4),
          TextButton(onPressed: null, child: const Text('Next')),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> products) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        crossAxisSpacing: 11,
        mainAxisSpacing: 11,
        childAspectRatio: 1.8,
      ),
      itemCount: products.length,
      itemBuilder: (_, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final quantity = _intValue(product['quantity']);
    final minimum = _intValue(product['min_stock']);
    final price = _doubleValue(product['price']);
    final low = quantity <= minimum;
    final colorScheme = Theme.of(context).colorScheme;
    final stockColor = low ? colorScheme.tertiary : colorScheme.primary;

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(_isGridView ? 8 : 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: _isGridView
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: _isGridView ? 32 : 48,
                  height: _isGridView ? 32 : 48,
                  decoration: BoxDecoration(
                    color: low
                        ? colorScheme.tertiaryContainer
                        : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: low
                        ? colorScheme.onTertiaryContainer
                        : colorScheme.primary,
                    size: _isGridView ? 18 : 24,
                  ),
                ),
                SizedBox(width: _isGridView ? 7 : 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name']?.toString() ?? 'Unnamed product',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: _isGridView ? 12 : 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: _isGridView ? 2 : 4),
                        Text(
                          _categoryName(product),
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
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44),
                  tooltip: 'Product actions',
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await showDialog<void>(
                        context: context,
                        builder: (_) => ProductFormScreen(product: product),
                      );
                      _load();
                    } else if (value == 'in' || value == 'out') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StockTransactionScreen(
                            product: product,
                            type: value == 'in' ? 'IN' : 'OUT',
                          ),
                        ),
                      );
                      _load();
                    } else if (value == 'delete') {
                      _delete(_intValue(product['id']));
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit product'),
                    ),
                    const PopupMenuItem(value: 'in', child: Text('Stock in')),
                    const PopupMenuItem(value: 'out', child: Text('Stock out')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: _isGridView ? 4 : 13),
              child: const Divider(height: 1),
            ),
            if (_isGridView)
              Row(
                children: [
                  Expanded(
                    child: _productMetric('QTY', '$quantity units', stockColor),
                  ),
                  Expanded(
                    child: _productMetric(
                      'PRICE',
                      '₱${price.toStringAsFixed(2)}',
                      colorScheme.onSurface,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _productMetric(
                      'IN STOCK',
                      '$quantity units',
                      stockColor,
                    ),
                  ),
                  Expanded(
                    child: _productMetric(
                      'MINIMUM',
                      '$minimum units',
                      colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: _productMetric(
                      'PRICE',
                      '₱${price.toStringAsFixed(2)}',
                      colorScheme.onSurface,
                    ),
                  ),
                  if (low) _lowStockBadge(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _lowStockBadge() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        'LOW',
        style: TextStyle(
          color: colorScheme.onTertiaryContainer,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _productMetric(String label, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 9,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
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
