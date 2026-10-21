import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

class StockTransactionScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String type; // 'IN' or 'OUT'
  const StockTransactionScreen({
    super.key,
    required this.product,
    required this.type,
  });
  @override
  State<StockTransactionScreen> createState() => _StockTransactionScreenState();
}

class _StockTransactionScreenState extends State<StockTransactionScreen> {
  final _qty = TextEditingController(text: '1');
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<ApiService>().post('/stock', {
        'product_id': widget.product['id'],
        'type': widget.type,
        'quantity': int.tryParse(_qty.text) ?? 1,
        'note': _note.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIn = widget.type == 'IN';
    final accent = isIn ? const Color(0xFF25865B) : const Color(0xFFD65C54);
    final pale = isIn ? const Color(0xFFE5F5EE) : const Color(0xFFFFECEA);
    return Scaffold(
      appBar: AppBar(title: Text(isIn ? 'Stock in' : 'Stock out')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
          children: [
            Container(
              padding: const EdgeInsets.all(21),
              decoration: BoxDecoration(
                color: pale,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      isIn
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isIn
                              ? 'Add to inventory'
                              : 'Record a sale or removal',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product['name'],
                          style: const TextStyle(color: Color(0xFF526872)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 17),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT ON-HAND',
                            style: TextStyle(
                              color: Color(0xFF71818A),
                              letterSpacing: 0.9,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                        ],
                      ),
                    ),
                    Text(
                      '${widget.product['quantity']}',
                      style: const TextStyle(
                        color: Color(0xFF172B3A),
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'units',
                      style: TextStyle(color: Color(0xFF71818A)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'MOVEMENT DETAILS',
              style: TextStyle(
                color: Color(0xFF087E76),
                letterSpacing: 1,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 11),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _qty,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        helperText: isIn
                            ? 'How many units are being added?'
                            : 'How many units are being removed?',
                        prefixIcon: Icon(
                          isIn
                              ? Icons.add_circle_outline_rounded
                              : Icons.remove_circle_outline_rounded,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _note,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded),
                        hintText: 'Add a short note about this movement',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.shrink()
                    : Icon(isIn ? Icons.add_rounded : Icons.remove_rounded),
                label: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isIn ? 'Confirm stock in' : 'Confirm stock out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
