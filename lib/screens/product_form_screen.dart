import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

class ProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  const ProductFormScreen({super.key, this.product});
  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _price = TextEditingController(text: '0');
  final _qty = TextEditingController(text: '0');
  final _min = TextEditingController(text: '5');
  int? _categoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _saving = false;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _name.text = p['name'] ?? '';
      _sku.text = p['sku'] ?? '';
      _price.text = '${p['price'] ?? 0}';
      _qty.text = '${p['quantity'] ?? 0}';
      _min.text = '${p['min_stock'] ?? 5}';
      _categoryId = p['category_id'];
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _price.dispose();
    _qty.dispose();
    _min.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await context.read<ApiService>().get('/categories');
      if (mounted) {
        setState(
          () => _categories = (data as List).cast<Map<String, dynamic>>(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _categoryError = e.toString());
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final api = context.read<ApiService>();
      final body = {
        'name': _name.text.trim(),
        'category_id': _categoryId,
        'sku': _sku.text.trim(),
        'price': double.tryParse(_price.text) ?? 0,
        'quantity': int.tryParse(_qty.text) ?? 0,
        'min_stock': int.tryParse(_min.text) ?? 5,
      };
      if (widget.product == null) {
        await api.post('/products', body);
      } else {
        await api.put('/products/${widget.product!['id']}', body);
      }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add product' : 'Edit product'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF087E76), Color(0xFF075B63)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(21),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      widget.product == null
                          ? Icons.add_box_rounded
                          : Icons.edit_note_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product == null
                              ? 'Make room for something new'
                              : 'Keep your catalog up to date',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Add the details that help you stay organized.',
                          style: TextStyle(
                            color: Color(0xFFD7EEEA),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 21),
            const Text(
              'PRODUCT DETAILS',
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
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Product name',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                    ),
                    const SizedBox(height: 13),
                    DropdownButtonFormField<int>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c['id'],
                              child: Text(c['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    if (_categoryError != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _loadCategories,
                          icon: const Icon(Icons.refresh_rounded, size: 17),
                          label: const Text('Retry loading categories'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 13),
                    TextField(
                      controller: _sku,
                      decoration: const InputDecoration(
                        labelText: 'SKU / product code',
                        prefixIcon: Icon(Icons.qr_code_rounded),
                      ),
                    ),
                    const SizedBox(height: 13),
                    TextField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Unit price',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'STOCK SETTINGS',
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
                      enabled: widget.product == null,
                      decoration: InputDecoration(
                        labelText: widget.product == null
                            ? 'Starting quantity'
                            : 'Current quantity',
                        prefixIcon: const Icon(Icons.numbers_rounded),
                        helperText: widget.product == null
                            ? 'You can update this later with a stock movement.'
                            : 'Use stock in or stock out to update quantity.',
                      ),
                    ),
                    const SizedBox(height: 13),
                    TextField(
                      controller: _min,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Low-stock alert at',
                        prefixIcon: Icon(Icons.notifications_active_outlined),
                        helperText:
                            'Get flagged when stock reaches this level.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 23),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.shrink()
                    : const Icon(Icons.check_rounded),
                label: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.product == null ? 'Add product' : 'Save changes',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
