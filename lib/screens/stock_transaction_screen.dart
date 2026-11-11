import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class StockTransactionScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String type;

  const StockTransactionScreen({
    super.key,
    required this.product,
    required this.type,
  });

  @override
  State<StockTransactionScreen> createState() => _StockTransactionScreenState();
}

class _StockTransactionScreenState extends State<StockTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    final auth = Provider.of<AuthService?>(context, listen: false);
    final sessionRevision = auth?.sessionRevision;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await context.read<ApiService>().post('/stock', {
        'product_id': widget.product['id'],
        'type': widget.type,
        'quantity': int.parse(_qty.text.trim()),
        'note': _note.text.trim(),
      });
      if (mounted && auth?.sessionRevision == sessionRevision) {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Stock updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted && auth?.sessionRevision == sessionRevision) {
        messenger.showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isIn = widget.type == 'IN';
    final accent = isIn ? const Color(0xFF25865B) : colorScheme.error;
    final pale = accent.withValues(alpha: 0.15);
    final title = isIn ? 'Stock In' : 'Stock Out';
    final subtitle = widget.product['name']?.toString() ?? 'Inventory item';
    final onHand = widget.product['quantity']?.toString() ?? '0';
    final inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
      prefixIconColor: colorScheme.onSurfaceVariant,
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
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    );

    return Dialog(
      backgroundColor: colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
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
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
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
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: pale,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isIn
                                      ? Icons.add_box_outlined
                                      : Icons.point_of_sale_outlined,
                                  color: accent,
                                  size: 25,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    isIn ? 'Add to inventory' : 'Record a sale',
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$onHand units on hand',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            key: const ValueKey('stock-quantity'),
                            controller: _qty,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              prefixIcon: Icon(
                                isIn
                                    ? Icons.add_circle_outline_rounded
                                    : Icons.remove_circle_outline_rounded,
                              ),
                            ),
                            validator: (value) {
                              final quantity = int.tryParse(
                                value?.trim() ?? '',
                              );
                              if (quantity == null || quantity <= 0) {
                                return 'Enter a valid quantity';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
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
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: isIn
                            ? Colors.white
                            : colorScheme.onError,
                      ),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isIn ? Icons.add_rounded : Icons.remove_rounded,
                            ),
                      label: Text(
                        isIn ? 'Confirm stock in' : 'Confirm stock out',
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
