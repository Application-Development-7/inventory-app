import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../widgets/demand_forecast_card.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  List<Map<String, dynamic>> _products = [];
  String? _selectedProductId;
  Map<String, dynamic>? _trend;
  bool _productsLoading = true;
  bool _forecastLoading = false;
  List<Map<String, dynamic>> _topProducts = [];
  bool _topProductsLoading = true;
  String? _productsError;
  String? _forecastError;
  String? _topProductsError;
  int _forecastRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadTopProducts();
  }

  Future<void> _refresh() async {
    await Future.wait([_loadProducts(), _loadTopProducts()]);
  }

  Future<void> _loadTopProducts() async {
    setState(() {
      _topProductsLoading = true;
      _topProductsError = null;
    });
    try {
      final products = await context
          .read<ApiService>()
          .getTopProductsThisMonth();
      if (mounted) {
        setState(() {
          _topProducts = products;
          _topProductsLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _topProductsError = error.toString();
          _topProductsLoading = false;
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    _forecastRequestId++;
    setState(() {
      _productsLoading = true;
      _productsError = null;
    });
    try {
      final response = await context.read<ApiService>().get('/products');
      final products = (response as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      final selectedId =
          products.any(
            (product) => product['id'].toString() == _selectedProductId,
          )
          ? _selectedProductId
          : products.isEmpty
          ? null
          : products.first['id'].toString();
      setState(() {
        _products = products;
        _selectedProductId = selectedId;
        _productsLoading = false;
      });
      if (selectedId != null) {
        await _loadForecast(selectedId);
      } else {
        setState(() {
          _trend = null;
          _forecastError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _productsError = error.toString();
          _productsLoading = false;
        });
      }
    }
  }

  Future<void> _loadForecast(String productId) async {
    final requestId = ++_forecastRequestId;
    setState(() {
      _forecastLoading = true;
      _forecastError = null;
      _trend = null;
    });
    try {
      final response = await context.read<ApiService>().get(
        '/forecast/product/$productId',
      );
      final data = (response as Map).cast<String, dynamic>();
      final product = data['product'] as Map?;
      final productName =
          product?['name']?.toString() ??
          _products
              .where((item) => item['id'].toString() == productId)
              .firstOrNull?['name']
              ?.toString() ??
          'Product demand';
      if (mounted && requestId == _forecastRequestId) {
        setState(() {
          _trend = {...data, 'product_name': productName};
          _forecastLoading = false;
        });
      }
    } catch (error) {
      if (mounted && requestId == _forecastRequestId) {
        setState(() {
          _forecastError = error.toString();
          _forecastLoading = false;
        });
      }
    }
  }

  void _onProductSelected(String? productId) {
    if (productId == null || productId == _selectedProductId) return;
    setState(() => _selectedProductId = productId);
    _loadForecast(productId);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 25),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.auto_graph_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan with confidence',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Historical demand and six-month projections.',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 19),
          if (_productsLoading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(22),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_productsError != null)
            _messageCard(
              icon: Icons.error_outline_rounded,
              title: 'Products unavailable',
              message: _productsError!,
              action: FilledButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            )
          else if (_products.isEmpty)
            _messageCard(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
              message: 'Add a product to view its demand forecast.',
            )
          else ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedProductId,
              decoration: const InputDecoration(
                labelText: 'Select a product',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              items: _products.map((product) {
                final id = product['id'].toString();
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    product['name']?.toString() ?? 'Unnamed product',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _onProductSelected,
            ),
            const SizedBox(height: 16),
            if (_forecastLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_forecastError != null)
              _messageCard(
                icon: Icons.error_outline_rounded,
                title: 'Forecast unavailable',
                message: _forecastError!,
                action: FilledButton.icon(
                  onPressed: _selectedProductId == null
                      ? null
                      : () => _loadForecast(_selectedProductId!),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              )
            else if (_trend != null)
              DemandForecastCard(trend: _trend!)
            else
              _messageCard(
                icon: Icons.insights_rounded,
                title: 'Forecast not available',
                message: 'Select a product to view its forecast.',
              ),
          ],
          const SizedBox(height: 18),
          _topProductsSection(context),
        ],
      ),
    );
  }

  Widget _topProductsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Products This Month',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            if (_topProductsLoading)
              const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_topProductsError != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _topProductsError!,
                    style: TextStyle(color: colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadTopProducts,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              )
            else if (_topProducts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No products have sales recorded this month yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else ...[
              _topProductsBarChart(colorScheme),
              const SizedBox(height: 12),
              Text(
                'Recommendation: Stock up on ${_topProducts.first['product_name']} '
                'for next month based on current sales velocity.',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _topProductsBarChart(ColorScheme colorScheme) {
    final values = _topProducts
        .map((product) => (product['total_sold'] as num).toDouble())
        .toList();
    final maxY = math.max(1.0, values.reduce(math.max) * 1.2);
    final interval = maxY / 4;

    return SizedBox(
      height: 225,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final product = _topProducts[group.x];
                return BarTooltipItem(
                  '${product['product_name']}\n${rod.toY.toInt()} sold',
                  TextStyle(
                    color: colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
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
                reservedSize: 34,
                interval: interval,
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
                reservedSize: 42,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= _topProducts.length) {
                    return const SizedBox.shrink();
                  }
                  final name =
                      _topProducts[index]['product_name']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 56,
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: _topProducts.indexed.map((entry) {
            final (index, product) = entry;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (product['total_sold'] as num).toDouble(),
                  color: colorScheme.primary,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 5),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 14), action],
          ],
        ),
      ),
    );
  }
}
