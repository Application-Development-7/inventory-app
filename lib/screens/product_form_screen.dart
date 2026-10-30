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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );

    return Dialog(
      backgroundColor: colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Theme(
            data: theme.copyWith(inputDecorationTheme: inputDecorationTheme),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEW INVENTORY ITEM',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            widget.product == null
                                ? 'Add a product'
                                : 'Edit product',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Enter the product details below. It will appear at the top of your inventory.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Product name',
                            hintText: 'e.g. Arc Wireless Mouse',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _sku,
                                decoration: const InputDecoration(
                                  labelText: 'SKU',
                                  hintText: 'e.g. AW-2401',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _categoryId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                ),
                                items: _categories
                                    .map(
                                      (category) => DropdownMenuItem<int>(
                                        value: category['id'],
                                        child: Text(
                                          category['name'],
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _categoryId = value),
                              ),
                            ),
                          ],
                        ),
                        if (_categoryError != null) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _loadCategories,
                              icon: const Icon(Icons.refresh_rounded, size: 17),
                              label: const Text('Retry loading categories'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _qty,
                                keyboardType: TextInputType.number,
                                enabled: widget.product == null,
                                decoration: InputDecoration(
                                  labelText: 'Initial stock',
                                  hintText: '0',
                                  helperText: widget.product == null
                                      ? null
                                      : 'Managed with stock movements',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _price,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Unit price',
                                  hintText: '0.00',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _min,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minimum stock',
                            hintText: '5',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_rounded),
                      label: Text(
                        widget.product == null ? 'Add product' : 'Save',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
