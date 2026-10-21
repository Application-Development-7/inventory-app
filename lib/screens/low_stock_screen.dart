import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});
  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

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
        setState(() {
          _items = (data as List).cast<Map<String, dynamic>>();
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

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 25),
        children: [
          Container(
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
                        '${_items.length} ${_items.length == 1 ? 'product needs' : 'products need'} attention',
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
          ),
          const SizedBox(height: 20),
          if (_error != null && _items.isEmpty)
            Card(
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
            )
          else if (_items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 34,
                ),
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
            )
          else
            ..._items.map((p) {
              final quantity = p['quantity'] as int;
              final minimum = p['min_stock'] as int;
              final shortage = (minimum - quantity).clamp(0, minimum);
              final progress = minimum <= 0
                  ? 0.0
                  : (quantity / minimum).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1E3),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.inventory_2_rounded,
                                color: Color(0xFFE28B43),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Color(0xFF172B3A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    p['category_name'] ?? 'Inventory item',
                                    style: const TextStyle(
                                      color: Color(0xFF71818A),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1E3),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Text(
                                'LOW STOCK',
                                style: TextStyle(
                                  color: Color(0xFFB56A2A),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$quantity',
                              style: const TextStyle(
                                color: Color(0xFF172B3A),
                                fontWeight: FontWeight.w800,
                                fontSize: 23,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 3),
                              child: Text(
                                '  in stock',
                                style: TextStyle(color: Color(0xFF71818A)),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$minimum minimum',
                              style: const TextStyle(
                                color: Color(0xFF71818A),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFF3E6D9),
                            color: const Color(0xFFE28B43),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          shortage == 0
                              ? 'At your minimum level'
                              : 'Short by $shortage ${shortage == 1 ? 'unit' : 'units'} to reach minimum',
                          style: const TextStyle(
                            color: Color(0xFF9A6A42),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
