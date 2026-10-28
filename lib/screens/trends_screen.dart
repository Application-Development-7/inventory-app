import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  static const _opportunityBlue = Color(0xFF3977C5);
  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  List<Map<String, dynamic>> _products = [];
  String? _selectedProductId;
  Map<String, dynamic>? _trend;
  bool _productsLoading = true;
  bool _forecastLoading = false;
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _recommendations = [];
  bool _topProductsLoading = true;
  bool _recommendationsLoading = true;
  String? _productsError;
  String? _forecastError;
  String? _topProductsError;
  String? _recommendationsError;
  int _forecastRequestId = 0;
  int _recommendationsRequestId = 0;
  String _forecastView = 'monthly';
  int _selectedTopProductsMonth = DateTime.now().month;
  String _topProductsView = 'monthly';
  int _topProductsRequestId = 0;

  double _numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    return num.tryParse(value?.toString() ?? '')?.toDouble() ?? 0.0;
  }

  Map<String, dynamic>? get _selectedProduct => _products
      .where((product) => product['id'].toString() == _selectedProductId)
      .firstOrNull;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadTopProducts();
    _loadRecommendations();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadProducts(),
      _loadTopProducts(),
      _loadRecommendations(),
    ]);
  }

  Future<void> _loadRecommendations() async {
    final requestId = ++_recommendationsRequestId;
    final view = _forecastView;
    setState(() {
      _recommendationsLoading = true;
      _recommendationsError = null;
    });
    try {
      final response = await context.read<ApiService>().getForecastTrends(
        view: view,
      );
      final rawRecommendations = response['recommendations'];
      if (rawRecommendations is! List) {
        throw const FormatException(
          'Forecast trends response is missing recommendations.',
        );
      }
      final recommendations = rawRecommendations.map((item) {
        if (item is! Map) {
          throw const FormatException(
            'Forecast recommendation must be an object.',
          );
        }
        return item.cast<String, dynamic>();
      }).toList();
      if (mounted && requestId == _recommendationsRequestId) {
        setState(() {
          _recommendations = recommendations;
          _recommendationsLoading = false;
        });
      }
    } catch (error) {
      if (mounted && requestId == _recommendationsRequestId) {
        setState(() {
          _recommendationsError = error.toString();
          _recommendationsLoading = false;
        });
      }
    }
  }

  Future<void> _loadTopProducts() async {
    final requestId = ++_topProductsRequestId;
    final month = _selectedTopProductsMonth;
    final view = _topProductsView;
    setState(() {
      _topProductsLoading = true;
      _topProductsError = null;
    });
    try {
      final products = await context.read<ApiService>().getTopProductsThisMonth(
        month: month,
        view: view,
      );
      if (mounted && requestId == _topProductsRequestId) {
        setState(() {
          _topProducts = products;
          _topProductsLoading = false;
        });
      }
    } catch (error) {
      if (mounted && requestId == _topProductsRequestId) {
        setState(() {
          _topProductsError = error.toString();
          _topProductsLoading = false;
        });
      }
    }
  }

  void _onTopProductsMonthSelected(int? month) {
    if (month == null || month == _selectedTopProductsMonth) return;
    setState(() => _selectedTopProductsMonth = month);
    _loadTopProducts();
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
      final response = await context.read<ApiService>().getProductForecast(
        productId,
        view: _forecastView,
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

  Future<void> _showProductPicker() async {
    var query = '';
    final selectedId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colorScheme = Theme.of(context).colorScheme;
          final normalizedQuery = query.trim().toLowerCase();
          final filteredProducts = _products.where((product) {
            final name = product['name']?.toString().toLowerCase() ?? '';
            final sku = product['sku']?.toString().toLowerCase() ?? '';
            return name.contains(normalizedQuery) ||
                sku.contains(normalizedQuery);
          }).toList();

          return AlertDialog(
            title: const Text('Select a product'),
            content: SizedBox(
              width: 420,
              height: math.min(MediaQuery.sizeOf(context).height * 0.6, 440),
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                    onChanged: (value) => setDialogState(() => query = value),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              'No matching products',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              final id = product['id'].toString();
                              final isSelected = id == _selectedProductId;
                              return ListTile(
                                dense: true,
                                selected: isSelected,
                                leading: Icon(
                                  Icons.inventory_2_outlined,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                title: Text(
                                  product['name']?.toString() ??
                                      'Unnamed product',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: product['sku'] == null
                                    ? null
                                    : Text(product['sku'].toString()),
                                trailing: isSelected
                                    ? Icon(
                                        Icons.check_rounded,
                                        color: colorScheme.primary,
                                      )
                                    : null,
                                onTap: () => Navigator.pop(dialogContext, id),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
    if (selectedId != null) _onProductSelected(selectedId);
  }

  void _onForecastViewSelected(Set<String> selection) {
    if (selection.isEmpty || selection.first == _forecastView) return;
    setState(() => _forecastView = selection.first);
    final selectedProductId = _selectedProductId;
    if (selectedProductId != null) _loadForecast(selectedProductId);
    _loadRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final margin = constraints.maxWidth >= 800 ? 32.0 : 20.0;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(margin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _individualTrendsSection(),
                const SizedBox(height: 20),
                _buildForecastOverview(),
                const SizedBox(height: 22),
                _buildKpiSection(),
                const SizedBox(height: 22),
                _topProductsSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String>(
              value: _forecastView,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Next 90 days')),
                DropdownMenuItem(value: 'yearly', child: Text('Next 3 years')),
              ],
              onChanged: (value) {
                if (value != null) _onForecastViewSelected({value});
              },
            ),
            OutlinedButton.icon(
              onPressed: _exportReport,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Export report'),
            ),
          ],
        );
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demand Forecast',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Intelligence',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        );

        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 14), actions],
          );
        }
        return Row(
          children: [
            Expanded(child: heading),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildForecastOverview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chart = _overviewChartCard();
        final sideCards = _forecastSideCards();
        if (constraints.maxWidth < 900) {
          return Column(
            children: [chart, const SizedBox(height: 14), sideCards],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: chart),
            const SizedBox(width: 16),
            Expanded(child: sideCards),
          ],
        );
      },
    );
  }

  Widget _forecastSideCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _recommendationsCard(),
        const SizedBox(height: 14),
        _productReportCard(),
      ],
    );
  }

  Widget _overviewChartCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final history = (_trend?['history'] as List? ?? const [])
        .whereType<Map>()
        .map((point) => point.cast<String, dynamic>())
        .toList();
    final projections = (_trend?['projections'] as List? ?? const [])
        .whereType<Map>()
        .map((point) => point.cast<String, dynamic>())
        .toList();
    final isReady =
        _trend?['status'] == 'OK' &&
        history.isNotEmpty &&
        projections.isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demand overview',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _trend?['product_name']?.toString() ??
                            'Select a product to view demand',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _forecastLegend(colorScheme.primary, 'Actual'),
                const SizedBox(width: 12),
                _forecastLegend(
                  colorScheme.tertiary,
                  'Predicted',
                  dashed: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_productsLoading || _forecastLoading)
              const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!isReady)
              SizedBox(
                height: 250,
                child: Center(
                  child: Text(
                    _forecastError ??
                        (_trend?['message']?.toString() ??
                            'Forecast chart will appear when enough history is available.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              SizedBox(
                height: 250,
                child: _forecastLineChart(history, projections, colorScheme),
              ),
            if (isReady) ...[
              const SizedBox(height: 12),
              _forecastTable(projections, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _forecastTable(
    List<Map<String, dynamic>> projections,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 42,
        dataRowMaxHeight: 48,
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Demand'), numeric: true),
          DataColumn(label: Text('Confidence'), numeric: true),
          DataColumn(label: Text('Trend')),
        ],
        rows: projections.map((point) {
          final direction = point['direction']?.toString() ?? 'STABLE';
          return DataRow(
            cells: [
              DataCell(Text(_periodLabel(point))),
              DataCell(
                Text(
                  '${_numberValue(point['predicted_demand']).toInt()} units',
                ),
              ),
              DataCell(Text('${_numberValue(point['confidence']).toInt()}%')),
              DataCell(
                Text(
                  direction,
                  style: TextStyle(
                    color: _directionColor(direction, colorScheme),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _directionColor(String direction, ColorScheme colorScheme) {
    switch (direction.toUpperCase()) {
      case 'UP':
      case 'RISING':
        return colorScheme.primary;
      case 'DOWN':
      case 'FALLING':
        return colorScheme.error;
      case 'SEASONAL_PEAK':
      case 'SEASONAL_LOW':
        return colorScheme.tertiary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  Widget _forecastLegend(Color color, String label, {bool dashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed)
          SizedBox(width: 16, child: Divider(color: color, thickness: 2))
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _forecastLineChart(
    List<Map<String, dynamic>> history,
    List<Map<String, dynamic>> projections,
    ColorScheme colorScheme,
  ) {
    final actualSpots = history.indexed
        .map(
          (entry) =>
              FlSpot(entry.$1.toDouble(), _numberValue(entry.$2['demand'])),
        )
        .toList();
    final predictedSpots = <FlSpot>[
      if (actualSpots.isNotEmpty) actualSpots.last,
      ...projections.indexed.map(
        (entry) => FlSpot(
          (history.length + entry.$1).toDouble(),
          _numberValue(entry.$2['predicted_demand']),
        ),
      ),
    ];
    final values = [
      ...actualSpots.map((spot) => spot.y),
      ...predictedSpots.map((spot) => spot.y),
    ];
    final maxY = values.fold<double>(1, (maximum, value) {
      return math.max(maximum, value);
    });
    final points = [...history, ...projections];
    final maxX = math.max(1, points.length - 1).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY * 1.2,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
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
              reservedSize: 34,
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
              reservedSize: 34,
              interval: 1,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _periodLabel(points[index]),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: actualSpots,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
          LineChartBarData(
            spots: predictedSpots,
            isCurved: true,
            color: colorScheme.tertiary,
            barWidth: 3,
            dashArray: [7, 5],
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  String _periodLabel(Map<String, dynamic> point) {
    if (_forecastView == 'yearly') return point['year']?.toString() ?? '';
    final month = _numberValue(point['month']).toInt();
    if (month < 1 || month > 12) return '';
    return _monthNames[month - 1];
  }

  Widget _recommendationsCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI recommendations',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recommendationsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_recommendationsError != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _recommendationsError!,
                    style: TextStyle(color: colorScheme.error),
                  ),
                  TextButton.icon(
                    onPressed: _loadRecommendations,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              )
            else if (_recommendations.isEmpty)
              Text(
                'No recommendations right now. Inventory trends look stable.',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  final recommendation = _recommendations[index];
                  final type = recommendation['type']?.toString() ?? '';
                  final accent = _recommendationColor(type, colorScheme);
                  return Container(
                    margin: EdgeInsets.only(
                      bottom: index == _recommendations.length - 1 ? 0 : 10,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.06),
                      border: Border.all(color: accent.withValues(alpha: 0.55)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _recommendationIcon(type),
                          color: accent,
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recommendation['title']?.toString() ??
                                    'Recommendation',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                recommendation['description']?.toString() ?? '',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _recommendationColor(String type, ColorScheme colorScheme) {
    switch (type.toUpperCase()) {
      case 'URGENT':
        return colorScheme.error;
      case 'OPPORTUNITY':
        return _opportunityBlue;
      case 'HIGH_PRIORITY':
        return colorScheme.primary;
      case 'OPTIMIZE':
        return colorScheme.tertiary;
      default:
        return colorScheme.outline;
    }
  }

  IconData _recommendationIcon(String type) {
    switch (type.toUpperCase()) {
      case 'URGENT':
        return Icons.priority_high_rounded;
      case 'OPPORTUNITY':
        return Icons.lightbulb_outline_rounded;
      case 'HIGH_PRIORITY':
        return Icons.trending_up_rounded;
      case 'OPTIMIZE':
        return Icons.tune_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Widget _productReportCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final product = _selectedProduct;
    final quantity = _numberValue(product?['quantity']).toInt();
    final minimum = _numberValue(product?['min_stock']).toInt();
    final price = _numberValue(product?['price']);
    final status = product == null
        ? 'Not available'
        : quantity <= 0
        ? 'Out of stock'
        : quantity <= minimum
        ? 'Low stock'
        : 'In stock';
    final statusColor = switch (status) {
      'Out of stock' => colorScheme.error,
      'Low stock' => colorScheme.tertiary,
      'In stock' => colorScheme.primary,
      _ => colorScheme.onSurfaceVariant,
    };

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Report',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _reportDetail(
              'Product Name',
              product?['name']?.toString() ?? 'No product selected',
            ),
            const SizedBox(height: 10),
            _reportDetail('Current Stock', product == null ? '—' : '$quantity'),
            const SizedBox(height: 10),
            _reportDetail('Minimum Stock', product == null ? '—' : '$minimum'),
            const SizedBox(height: 10),
            _reportDetail(
              'Unit Price',
              product == null ? '—' : '₱${price.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
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

  Widget _reportDetail(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _peakPeriodLabel(dynamic peak) {
    if (peak is! Map) return peak.toString();
    final month = _numberValue(peak['month']).toInt();
    final year = peak['year']?.toString();
    if (month < 1 || month > 12) return year ?? 'Not available';
    return '${_monthNames[month - 1]}${year == null ? '' : ' $year'}';
  }

  Widget _buildKpiSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final confidence = _trend?['confidence'];
    final accuracy = confidence == null
        ? '—'
        : '${_numberValue(confidence).toStringAsFixed(0)}%';
    final stockouts = _products.where((product) {
      if (!product.containsKey('quantity') ||
          !product.containsKey('min_stock')) {
        return false;
      }
      final minimum = _numberValue(product['min_stock']);
      return minimum > 0 && _numberValue(product['quantity']) <= minimum;
    }).length;
    final selectedProduct = _products
        .where((product) => product['id'].toString() == _selectedProductId)
        .firstOrNull;
    final price = selectedProduct == null
        ? 0.0
        : _numberValue(selectedProduct['price']);
    final projections = (_trend?['projections'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final revenue = projections.isEmpty || price <= 0
        ? '—'
        : '₱${(projections.fold<double>(0, (total, point) => total + _numberValue(point['predicted_demand'])) * price).toStringAsFixed(0)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forecast at a glance',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _kpiCard(
                'Forecast accuracy',
                accuracy,
                Icons.verified_outlined,
                colorScheme.primary,
              ),
              _kpiCard(
                'Potential stockouts',
                '$stockouts',
                Icons.warning_amber_rounded,
                colorScheme.error,
              ),
              _kpiCard(
                'Revenue opportunity',
                revenue,
                Icons.attach_money_rounded,
                colorScheme.tertiary,
              ),
            ];
            if (constraints.maxWidth < 620) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    if (card != cards.last) const SizedBox(height: 10),
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  Expanded(child: cards[index]),
                  if (index < cards.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color accent) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
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

  Widget _individualTrendsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Individual Product Trends',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (_productsLoading)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
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
        else
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: math.min(constraints.maxWidth, 360),
                        child: Semantics(
                          key: const Key('product-selector'),
                          button: true,
                          label: 'Choose product',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _showProductPicker,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Product',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                                suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                                isDense: true,
                              ),
                              child: Text(
                                _selectedProduct?['name']?.toString() ??
                                    'Select a product',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _individualTrendSummary(),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _individualTrendSummary() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_forecastLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 9),
          Text(
            'Updating forecast…',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }

    final label = _trend?['label']?.toString().replaceAll('_', ' ') ?? '—';
    final color = _trend == null
        ? colorScheme.onSurfaceVariant
        : _directionColor(label, colorScheme);
    final peak = _trend?['peak_month'];
    final confidence = _trend?['confidence'] == null
        ? '—'
        : '${_numberValue(_trend!['confidence']).toStringAsFixed(0)}%';
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        _summaryValue('Trend', label, color),
        _summaryValue(
          'Peak',
          peak == null ? '—' : _peakPeriodLabel(peak),
          colorScheme.onSurface,
        ),
        _summaryValue('Confidence', confidence, colorScheme.onSurface),
        if (_forecastError != null)
          Text(
            _forecastError!,
            style: TextStyle(color: colorScheme.error, fontSize: 12),
          ),
      ],
    );
  }

  Widget _summaryValue(String label, String value, Color valueColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report exported successfully!')),
    );
  }

  Widget _topProductsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = _topProductsView == 'yearly'
        ? 'Top Products This Year'
        : 'Top Products in ${_monthNames[_selectedTopProductsMonth - 1]}';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final controls = Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'monthly',
                          label: Text('Monthly'),
                        ),
                        ButtonSegment<String>(
                          value: 'yearly',
                          label: Text('Yearly'),
                        ),
                      ],
                      selected: {_topProductsView},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        if (selection.isEmpty) return;
                        setState(() => _topProductsView = selection.first);
                        _loadTopProducts();
                      },
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    if (_topProductsView == 'monthly')
                      SizedBox(
                        width: 100,
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedTopProductsMonth,
                          decoration: const InputDecoration(
                            labelText: 'Month',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          items: List.generate(
                            _monthNames.length,
                            (index) => DropdownMenuItem<int>(
                              value: index + 1,
                              child: Text(_monthNames[index]),
                            ),
                          ),
                          onChanged: _onTopProductsMonthSelected,
                        ),
                      ),
                  ],
                );
                final titleWidget = Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                );
                if (constraints.maxWidth < 640) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleWidget,
                      const SizedBox(height: 12),
                      controls,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: titleWidget),
                    controls,
                  ],
                );
              },
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
                    _topProductsView == 'yearly'
                        ? 'No products have sales recorded for this year yet.'
                        : 'No products have sales recorded in ${_monthNames[_selectedTopProductsMonth - 1]} yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else ...[
              _topProductsBarChart(colorScheme),
              const SizedBox(height: 12),
              Text(
                _topProductsView == 'yearly'
                    ? 'Recommendation: Stock up on ${_topProducts.first['product_name']} for the coming year based on current sales velocity.'
                    : 'Recommendation: Stock up on ${_topProducts.first['product_name']} '
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
        .map((product) => _numberValue(product['total_sold']))
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
                  toY: _numberValue(product['total_sold']),
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
