import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DemandForecastCard extends StatelessWidget {
  final Map<String, dynamic> trend;

  const DemandForecastCard({super.key, required this.trend});

  static const _teal = Color(0xFF087E76);
  static const _blue = Color(0xFF3977C5);

  List<Map<String, dynamic>> get _history =>
      (trend['history'] as List? ?? const []).cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get _projections =>
      (trend['projections'] as List? ?? const []).cast<Map<String, dynamic>>();

  double _numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    return num.tryParse(value?.toString() ?? '')?.toDouble() ?? 0.0;
  }

  String _monthLabel(Map<String, dynamic> point) {
    const months = [
      '',
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
    final month = _numberValue(point['month']).toInt();
    if (month < 1 || month > 12) return '';
    return months[month];
  }

  String _periodLabel(Map<String, dynamic> point) {
    if (trend['view'] == 'yearly') {
      return point['year']?.toString() ?? '';
    }
    return _monthLabel(point);
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;
    final projections = _projections;
    final isYearly = trend['view'] == 'yearly';
    final colorScheme = Theme.of(context).colorScheme;
    final label = trend['label']?.toString().replaceAll('_', ' ') ?? 'TREND';
    final confidence = _numberValue(trend['confidence']).toInt();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demand Forecast & Trend Analysis',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              trend['product_name']?.toString() ?? 'Product demand',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(
                  icon: Icons.trending_up_rounded,
                  label: label,
                  color: _teal,
                ),
                _SummaryChip(
                  icon: Icons.verified_outlined,
                  label: '$confidence% confidence',
                  color: _blue,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (trend['status'] != 'OK' ||
                history.isEmpty ||
                projections.isEmpty)
              _insufficientData(context)
            else ...[
              _chart(context, history, projections),
              const SizedBox(height: 20),
              Text(
                isYearly ? 'YEARLY FORECAST' : 'MONTHLY FORECAST',
                style: TextStyle(
                  color: _teal,
                  letterSpacing: 1,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 22,
                  horizontalMargin: 8,
                  headingRowHeight: 40,
                  dataRowMinHeight: 42,
                  dataRowMaxHeight: 48,
                  columns: [
                    DataColumn(label: Text(isYearly ? 'Year' : 'Date')),
                    DataColumn(label: Text('Demand'), numeric: true),
                    DataColumn(label: Text('Confidence'), numeric: true),
                    DataColumn(label: Text('Trend')),
                  ],
                  rows: projections.map((point) {
                    return DataRow(
                      cells: [
                        DataCell(Text(_periodLabel(point))),
                        DataCell(
                          Text(
                            '${_numberValue(point['predicted_demand']).toInt()} units',
                          ),
                        ),
                        DataCell(
                          Text('${_numberValue(point['confidence']).toInt()}%'),
                        ),
                        DataCell(
                          Text(
                            point['direction']?.toString() ?? 'STABLE',
                            style: TextStyle(
                              color: _directionColor(
                                context,
                                point['direction']?.toString() ?? 'STABLE',
                              ),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chart(
    BuildContext context,
    List<Map<String, dynamic>> history,
    List<Map<String, dynamic>> projections,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final historicalSpots = history.indexed.map((entry) {
      final (index, point) = entry;
      return FlSpot(index.toDouble(), _numberValue(point['demand']));
    }).toList();

    final projectedSpots = <FlSpot>[
      if (historicalSpots.isNotEmpty) historicalSpots.last,
      ...projections.indexed.map((entry) {
        final (index, point) = entry;
        return FlSpot(
          (history.length + index).toDouble(),
          _numberValue(point['predicted_demand']),
        );
      }),
    ];
    final allValues = [
      ...historicalSpots.map((spot) => spot.y),
      ...projectedSpots.map((spot) => spot.y),
    ];
    final maxY = allValues.fold<double>(1, (max, value) {
      return value > max ? value : max;
    });
    final chartPoints = [...history, ...projections];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(color: _teal, label: 'Historical'),
            const SizedBox(width: 18),
            _LegendDot(color: _blue, label: 'Projected'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (chartPoints.length - 1).toDouble(),
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
                    reservedSize: 36,
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
                    reservedSize: 30,
                    interval: trend['view'] == 'yearly' ? 1 : 3,
                    getTitlesWidget: (value, _) {
                      final index = value.round();
                      if (index < 0 ||
                          index >= chartPoints.length ||
                          (value - index).abs() > 0.1) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _periodLabel(chartPoints[index]),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: historicalSpots,
                  isCurved: true,
                  color: _teal,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _teal.withValues(alpha: 0.08),
                  ),
                ),
                LineChartBarData(
                  spots: projectedSpots,
                  isCurved: true,
                  color: _blue,
                  barWidth: 2.5,
                  dashArray: [7, 4],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _insufficientData(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        trend['message']?.toString() ??
            'Not enough history to build a demand forecast yet.',
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Color _directionColor(BuildContext context, String direction) {
    switch (direction) {
      case 'UP':
        return const Color(0xFF25865B);
      case 'DOWN':
        return const Color(0xFFD65C54);
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
