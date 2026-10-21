import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});
  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  List<Map<String, dynamic>> _trends = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await context.read<ApiService>().get('/forecast/trends');
      if (mounted) {
        setState(() => _trends = (data as List).cast<Map<String, dynamic>>());
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

  Color _labelColor(String label) {
    switch (label) {
      case 'RISING':
        return const Color(0xFF25865B);
      case 'FALLING':
        return const Color(0xFFD65C54);
      case 'SEASONAL_PEAK':
        return const Color(0xFFE28B43);
      case 'SEASONAL_LOW':
        return const Color(0xFF3977C5);
      default:
        return const Color(0xFF71818A);
    }
  }

  String _monthName(int m) {
    const names = [
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
    if (m < 1 || m >= names.length) return '';
    return names[m];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 25),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.auto_graph_rounded,
                    color: Color(0xFF3977C5),
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan with confidence',
                        style: TextStyle(
                          color: Color(0xFF214B7B),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Demand signals based on your sales history.',
                        style: TextStyle(color: Color(0xFF52749C)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 19),
          if (_trends.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 22, vertical: 34),
                child: Column(
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      color: Color(0xFF9AABB0),
                      size: 42,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No trend data yet',
                      style: TextStyle(
                        color: Color(0xFF172B3A),
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Keep recording stock movements to unlock useful forecasts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF71818A)),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._trends.map((t) {
              if (t['status'] != 'OK') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F3F4),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.hourglass_empty_rounded,
                          color: Color(0xFF71818A),
                        ),
                      ),
                      title: Text(
                        t['product_name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(t['message'] ?? 'Not enough data'),
                      ),
                    ),
                  ),
                );
              }
              final forecast = t['forecast'];
              final peak = t['peak_month'];
              final labelColor = _labelColor(t['label']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t['product_name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: Color(0xFF172B3A),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: labelColor.withValues(alpha: 0.11),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                (t['label'] as String).replaceAll('_', ' '),
                                style: TextStyle(
                                  color: labelColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 17),
                        Row(
                          children: [
                            Expanded(
                              child: _infoItem(
                                Icons.local_fire_department_rounded,
                                'Peak month',
                                '${_monthName(peak['month'])} · x${peak['index']}',
                              ),
                            ),
                            Expanded(
                              child: _infoItem(
                                Icons.trending_up_rounded,
                                'Direction',
                                t['trend']['direction'],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF5F2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event_available_rounded,
                                color: Color(0xFF087E76),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${_monthName(forecast['month'])} ${forecast['year']} forecast',
                                  style: const TextStyle(
                                    color: Color(0xFF315A56),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                '${forecast['predicted_demand']} units',
                                style: const TextStyle(
                                  color: Color(0xFF087E76),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              size: 14,
                              color: Color(0xFF9AABB0),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${t['confidence']}% confidence · ${t['data_points']} months of data',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF71818A),
                              ),
                            ),
                          ],
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

  Widget _infoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF71818A)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF71818A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF314657),
          ),
        ),
      ],
    );
  }
}
