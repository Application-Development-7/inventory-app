import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

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

  List<Map<String, dynamic>> get _filteredItems => _items
      .where(
        (item) =>
            _selectedCategory == _allCategories ||
            _categoryName(item) == _selectedCategory,
      )
      .toList();

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
    final filteredItems = _filteredItems;
    final categories = [_allCategories, ..._categories];

    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            sliver: SliverToBoxAdapter(
              child: _buildSummaryCard(filteredItems.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: categories.contains(_selectedCategory)
                          ? _selectedCategory
                          : _allCategories,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
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
          ),
          if (_error != null && _items.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(child: _buildErrorCard()),
            )
          else if (_items.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(child: _buildEmptyCard()),
            )
          else if (filteredItems.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(child: _buildNoMatchesCard()),
            )
          else if (_isGridView)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 25),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 11,
                  mainAxisExtent: 220,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildLowStockCard(filteredItems[index], isGrid: true),
                  childCount: filteredItems.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 25),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: _buildLowStockCard(filteredItems[index]),
                  ),
                  childCount: filteredItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int filteredCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFE28B43),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$filteredCount ${filteredCount == 1 ? 'product needs' : 'products need'} attention',
                  style: const TextStyle(
                    color: Color(0xFF75451F),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Restock before you run out.',
                  style: TextStyle(color: Color(0xFF9A6A42)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFF9AABB0),
              size: 38,
            ),
            const SizedBox(height: 10),
            const Text('Could not load low-stock items'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F4F0),
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF087E76),
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'All stocked up',
              style: TextStyle(
                color: Color(0xFF172B3A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'All products are above their minimum stock levels.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF71818A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchesCard() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8EA)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No low-stock products in this category.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF71818A)),
        ),
      ),
    );
  }

  Widget _buildLowStockCard(Map<String, dynamic> item, {bool isGrid = false}) {
    final quantity = _intValue(item['quantity']);
    final minimum = _intValue(item['min_stock']);
    final progress = minimum <= 0 ? 0.0 : (quantity / minimum).clamp(0.0, 1.0);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFE57373).withValues(alpha: 0.4)),
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
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: const Color(0xFFD94F4F),
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
                          color: const Color(0xFF172B3A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _categoryName(item),
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
                if (!isGrid) ...[const SizedBox(width: 8), _lowStockBadge()],
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
                    const Color(0xFFD94F4F),
                    isGrid,
                  ),
                ),
                Expanded(
                  child: _stockValue(
                    'MINIMUM STOCK',
                    '$minimum',
                    const Color(0xFF71818A),
                    isGrid,
                  ),
                ),
                if (isGrid) _lowStockBadge(),
              ],
            ),
            SizedBox(height: isGrid ? 7 : 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: isGrid ? 5 : 7,
                backgroundColor: const Color(0xFFFBE4E5),
                color: const Color(0xFFD94F4F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockValue(String label, String value, Color color, bool isGrid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF9AABB0),
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

  Widget _lowStockBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Text(
        'LOW',
        style: TextStyle(
          color: Color(0xFFB53F48),
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
