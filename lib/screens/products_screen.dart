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
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String _search = '';

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
        setState(() => _products = (data as List).cast<Map<String, dynamic>>());
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

  @override
  Widget build(BuildContext context) {
    final filtered = _products
        .where(
          (p) => p['name'].toString().toLowerCase().contains(
            _search.toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 13),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search your products',
                suffixIcon: Icon(Icons.tune_rounded),
              ),
              onChanged: (v) => setState(() => _search = v),
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
                                _search.isEmpty
                                    ? Icons.inventory_2_outlined
                                    : Icons.search_off_rounded,
                                size: 52,
                                color: const Color(0xFF9AABB0),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                _search.isEmpty
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
                                _search.isEmpty
                                    ? 'Add your first product to start tracking stock.'
                                    : 'Try another product name.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF71818A),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final p = filtered[i];
                              final low =
                                  (p['quantity'] as int) <=
                                  (p['min_stock'] as int);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 11),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: low
                                                    ? const Color(0xFFFFF1E3)
                                                    : const Color(0xFFE7F4F0),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Icon(
                                                Icons.inventory_2_rounded,
                                                color: low
                                                    ? const Color(0xFFE28B43)
                                                    : const Color(0xFF087E76),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    p['name'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16,
                                                      color: Color(0xFF172B3A),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    p['category_name'] ??
                                                        'Uncategorized',
                                                    style: const TextStyle(
                                                      color: Color(0xFF71818A),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              tooltip: 'Product actions',
                                              onSelected: (v) async {
                                                if (v == 'edit') {
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ProductFormScreen(
                                                            product: p,
                                                          ),
                                                    ),
                                                  );
                                                  _load();
                                                } else if (v == 'in' ||
                                                    v == 'out') {
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          StockTransactionScreen(
                                                            product: p,
                                                            type: v == 'in'
                                                                ? 'IN'
                                                                : 'OUT',
                                                          ),
                                                    ),
                                                  );
                                                  _load();
                                                } else if (v == 'delete') {
                                                  _delete(p['id']);
                                                }
                                              },
                                              itemBuilder: (_) => const [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Edit product'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'in',
                                                  child: Text('Stock in'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'out',
                                                  child: Text('Stock out'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Color(0xFFB53F38),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 13,
                                          ),
                                          child: Divider(height: 1),
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _productMetric(
                                                'IN STOCK',
                                                '${p['quantity']} units',
                                                low
                                                    ? const Color(0xFFE28B43)
                                                    : const Color(0xFF087E76),
                                              ),
                                            ),
                                            Expanded(
                                              child: _productMetric(
                                                'MINIMUM',
                                                '${p['min_stock']} units',
                                                const Color(0xFF71818A),
                                              ),
                                            ),
                                            if (low)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 9,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFFF1E3,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                ),
                                                child: const Text(
                                                  'LOW',
                                                  style: TextStyle(
                                                    color: Color(0xFFB56A2A),
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
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
