import 'package:flutter/material.dart';

enum LegalDocument { termsOfService, privacyPolicy }

class LegalDocumentDialog extends StatelessWidget {
  final LegalDocument document;

  const LegalDocumentDialog({super.key, required this.document});

  static Future<void> show(
    BuildContext context,
    LegalDocument document,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => LegalDocumentDialog(document: document),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sections = _sectionsFor(document);
    final title = document == LegalDocument.termsOfService
        ? 'Terms of Service'
        : 'Privacy Policy';

    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Divider(color: colors.outlineVariant),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < sections.length; index++) ...[
                        if (index > 0) const SizedBox(height: 22),
                        Text(
                          sections[index].heading,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          sections[index].body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.55,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_LegalSection> _sectionsFor(LegalDocument document) {
    return switch (document) {
      LegalDocument.termsOfService => const [
        _LegalSection(
          '1. Acceptance of Terms',
          'By accessing and using Stockwise, you agree to be bound by these Terms of Service. If you do not agree, please do not use the application.',
        ),
        _LegalSection(
          '2. Description of Service',
          'Stockwise is an inventory management platform that provides real-time stock tracking, low-stock alerts, and AI-powered demand forecasting. The service is provided "as is" for informational and operational purposes.',
        ),
        _LegalSection(
          '3. Account Security',
          'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account.',
        ),
        _LegalSection(
          '4. AI Forecasting Disclaimer',
          'The demand forecasting and AI recommendations provided by Stockwise are predictive models based on historical data. They are not guaranteed to be 100% accurate and should be used as a supplementary tool, not a sole basis for financial or purchasing decisions.',
        ),
        _LegalSection(
          '5. Limitation of Liability',
          'Stockwise shall not be liable for any indirect, incidental, or consequential damages resulting from the use or inability to use the service, including but not limited to inventory loss or data inaccuracies.',
        ),
      ],
      LegalDocument.privacyPolicy => const [
        _LegalSection(
          '1. Information We Collect',
          'We collect your username, securely hashed passwords, and the inventory data you input (products, quantities, prices). We also log stock transactions and audit events (who added/edited/deleted items).',
        ),
        _LegalSection(
          '2. How We Use Your Data',
          'Your data is used solely to operate the application, generate AI forecasting models, display dashboard analytics, and maintain security logs. We do not sell your data to third parties.',
        ),
        _LegalSection(
          '3. Data Security',
          'We implement industry-standard security measures, including JWT (JSON Web Tokens) for authentication and Bcrypt password hashing. However, no method of electronic storage is 100% secure.',
        ),
        _LegalSection(
          '4. Data Retention',
          'Your data remains in our system until you choose to delete your account or specific inventory items. Deleted data may persist in backup archives for a limited time.',
        ),
        _LegalSection(
          '5. Your Rights',
          'You have the right to access, update, or delete the personal information and inventory data stored in your workspace.',
        ),
      ],
    };
  }
}

class _LegalSection {
  final String heading;
  final String body;

  const _LegalSection(this.heading, this.body);
}
