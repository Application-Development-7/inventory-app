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
      final matchesSearch = name.contains(_search.toLowerCase());
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
    final filtered = _visibleProducts;
    final categories = [_allCategories, ..._categories];

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 13),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Search your products',
                      suffixIcon: Icon(Icons.tune_rounded),
                    ),
                    onChanged: (value) => setState(() => _search = value),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 145,
                  child: DropdownButtonFormField<String>(
                    initialValue: categories.contains(_selectedCategory)
                        ? _selectedCategory
                        : _allCategories,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                    ),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (category) {
                      if (category != null) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSort,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sort by',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    items: _sortOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(
                              option,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (sort) {
                      if (sort != null) setState(() => _selectedSort = sort);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: _isGridView ? 'Show as list' : 'Show as grid',
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                  icon: Icon(
                    _isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Text(
                  'YOUR CATALOG',
                  style: TextStyle(
                    color: Color(0xFF087E76),
                    letterSpacing: 1,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filtered.length} ${filtered.length == 1 ? 'item' : 'items'}',
                  style: const TextStyle(
                    color: Color(0xFF71818A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(28),
                            children: [
                              const SizedBox(height: 60),
                              Icon(
                                _search.isEmpty &&
                                        _selectedCategory == _allCategories
                                    ? Icons.inventory_2_outlined
                                    : Icons.search_off_rounded,
                                size: 52,
                                color: const Color(0xFF9AABB0),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                _search.isEmpty &&
                                        _selectedCategory == _allCategories
                                    ? 'Your catalog is ready'
                                    : 'No matching products',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF172B3A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _search.isEmpty &&
                                        _selectedCategory == _allCategories
                                    ? 'Add your first product to start tracking stock.'
                                    : 'Try changing your search or category.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF71818A),
                                ),
                              ),
                            ],
                          )
                        : _isGridView
                        ? _buildGridView(filtered)
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                            itemCount: filtered.length,
                            itemBuilder: (_, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 11),
                              child: _buildProductCard(filtered[index]),
                            ),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add product'),
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
    final stockColor = low ? const Color(0xFFE28B43) : const Color(0xFF087E76);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8EA)),
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
                        ? const Color(0xFFFFF1E3)
                        : const Color(0xFFE7F4F0),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: low
                        ? const Color(0xFFE28B43)
                        : const Color(0xFF087E76),
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
                            color: const Color(0xFF172B3A),
                          ),
                        ),
                        SizedBox(height: _isGridView ? 2 : 4),
                        Text(
                          _categoryName(product),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF71818A),
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
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductFormScreen(product: product),
                        ),
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
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit product')),
                    PopupMenuItem(value: 'in', child: Text('Stock in')),
                    PopupMenuItem(value: 'out', child: Text('Stock out')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Color(0xFFB53F38)),
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
                      '\$${price.toStringAsFixed(2)}',
                      const Color(0xFF172B3A),
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
                      const Color(0xFF71818A),
                    ),
                  ),
                  Expanded(
                    child: _productMetric(
                      'PRICE',
                      '\$${price.toStringAsFixed(2)}',
                      const Color(0xFF172B3A),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E3),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Text(
        'LOW',
        style: TextStyle(
          color: Color(0xFFB56A2A),
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _productMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9AABB0),
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
