import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();
  final _preferencesFormKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _lowStockThresholdController =
      TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isUpdatingProfile = false;
  bool _isUpdatingPassword = false;
  bool _isRefreshingProfile = false;
  bool _isSavingPreferences = false;
  bool _isClearingInventory = false;
  bool _isDeletingAccount = false;
  String _currency = '₱';
  bool _notifyLowStock = true;
  bool _notifyWeeklySummary = true;
  String _originalUsername = '';
  String _originalDisplayName = '';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _displayNameController.text = auth.displayName ?? '';
    _usernameController.text = auth.username ?? '';
    _originalUsername = auth.username ?? '';
    _originalDisplayName = auth.displayName ?? '';
    _currency = auth.currency;
    _lowStockThresholdController.text = '${auth.lowStockThreshold}';
    _notifyLowStock = auth.notifyLowStock;
    _notifyWeeklySummary = auth.notifyWeeklySummary;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _lowStockThresholdController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_profileFormKey.currentState?.validate() != true) return;
    final auth = context.read<AuthService>();
    final sessionRevision = auth.sessionRevision;
    final messenger = ScaffoldMessenger.of(context);
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();
    if (username == _originalUsername.trim() &&
        displayName == _originalDisplayName.trim()) {
      _showMessage('No changes to save', isSuccess: false, isNeutral: true);
      return;
    }

    String? currentPassword;
    if (username != _originalUsername.trim()) {
      var enteredPassword = '';
      currentPassword = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm username change'),
          content: TextField(
            autofocus: true,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onChanged: (value) => enteredPassword = value,
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
            decoration: const InputDecoration(
              labelText: 'Current Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(enteredPassword),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (currentPassword == null ||
          !mounted ||
          auth.sessionRevision != sessionRevision) {
        return;
      }
    }

    setState(() => _isUpdatingProfile = true);
    try {
      await auth.updateProfile(
        username: _usernameController.text,
        displayName: _displayNameController.text,
        currentPassword: currentPassword,
      );
      if (mounted && auth.sessionRevision == sessionRevision) {
        _originalUsername = username;
        _originalDisplayName = displayName;
        _showMessage(
          'Profile updated successfully!',
          isSuccess: true,
          messenger: messenger,
        );
      }
    } catch (error) {
      if (mounted && auth.sessionRevision == sessionRevision) {
        _showMessage(
          _errorMessage(error),
          isSuccess: false,
          messenger: messenger,
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingProfile = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_securityFormKey.currentState?.validate() != true) return;
    final auth = context.read<AuthService>();
    final sessionRevision = auth.sessionRevision;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isUpdatingPassword = true);
    try {
      await auth.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted || auth.sessionRevision != sessionRevision) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showMessage(
        'Password updated successfully!',
        isSuccess: true,
        messenger: messenger,
      );
    } catch (error) {
      if (mounted && auth.sessionRevision == sessionRevision) {
        _showMessage(
          _errorMessage(error),
          isSuccess: false,
          messenger: messenger,
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  Future<void> _refreshProfile() async {
    final auth = context.read<AuthService>();
    final sessionRevision = auth.sessionRevision;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isRefreshingProfile = true);
    try {
      await auth.refreshProfile();
      if (!mounted || auth.sessionRevision != sessionRevision) return;
      _usernameController.text = auth.username ?? '';
      _displayNameController.text = auth.displayName ?? '';
      _originalUsername = _usernameController.text;
      _originalDisplayName = _displayNameController.text;
      _currency = auth.currency;
      _lowStockThresholdController.text = '${auth.lowStockThreshold}';
      _notifyLowStock = auth.notifyLowStock;
      _notifyWeeklySummary = auth.notifyWeeklySummary;
      _showMessage(
        'Profile refreshed successfully',
        isSuccess: true,
        messenger: messenger,
      );
    } catch (error) {
      if (mounted && auth.sessionRevision == sessionRevision) {
        _showMessage(
          _errorMessage(error),
          isSuccess: false,
          messenger: messenger,
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshingProfile = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final auth = context.read<AuthService>();
    final sessionRevision = auth.sessionRevision;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Are you sure you want to log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true &&
        mounted &&
        auth.sessionRevision == sessionRevision) {
      await auth.logout();
    }
  }

  Future<void> _savePreferences() async {
    if (_preferencesFormKey.currentState?.validate() != true) return;
    final auth = context.read<AuthService>();
    final sessionRevision = auth.sessionRevision;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSavingPreferences = true);
    try {
      await auth.updatePreferences(
        currency: _currency,
        lowStockThreshold: int.parse(_lowStockThresholdController.text.trim()),
        notifyLowStock: _notifyLowStock,
        notifyWeeklySummary: _notifyWeeklySummary,
      );
      if (mounted && auth.sessionRevision == sessionRevision) {
        _showMessage(
          'Preferences saved successfully',
          isSuccess: true,
          messenger: messenger,
        );
      }
    } catch (error) {
      if (mounted && auth.sessionRevision == sessionRevision) {
        _showMessage(
          _errorMessage(error),
          isSuccess: false,
          messenger: messenger,
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPreferences = false);
    }
  }

  Future<bool> _confirmDangerAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    var typedText = '';
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(message),
                  const SizedBox(height: 16),
                  TextField(
                    autofocus: true,
                    onChanged: (value) =>
                        setDialogState(() => typedText = value),
                    decoration: const InputDecoration(
                      labelText: 'Type DELETE to confirm',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: typedText == 'DELETE'
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  Future<void> _clearInventory() async {
    final confirmed = await _confirmDangerAction(
      title: 'Clear Inventory Data?',
      message:
          'Are you sure? This will delete all products. Type DELETE to confirm',
      confirmLabel: 'Clear Inventory',
    );
    if (!confirmed || !mounted) return;

    final auth = context.read<AuthService>();
    final sessionRevision = auth.sessionRevision;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isClearingInventory = true);
    try {
      await auth.clearInventory();
      if (mounted && auth.sessionRevision == sessionRevision) {
        _showMessage(
          'Inventory data cleared',
          isSuccess: true,
          messenger: messenger,
        );
      }
    } catch (error) {
      if (mounted && auth.sessionRevision == sessionRevision) {
        _showMessage(
          _errorMessage(error),
          isSuccess: false,
          messenger: messenger,
        );
      }
    } finally {
      if (mounted) setState(() => _isClearingInventory = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _confirmDangerAction(
      title: 'Delete Account?',
      message: 'This permanently deletes your account and its data. Type DELETE to confirm',
      confirmLabel: 'Delete Account',
    );
    if (!confirmed || !mounted) return;

    final auth = context.read<AuthService>();
    final sessionRevision = auth.sessionRevision;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isDeletingAccount = true);
    try {
      await auth.deleteAccount();
    } catch (error) {
      if (mounted && auth.sessionRevision == sessionRevision) {
        _showMessage(
          _errorMessage(error),
          isSuccess: false,
          messenger: messenger,
        );
      }
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  String _errorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    final normalizedMessage = message.toLowerCase();
    if (message.isEmpty ||
        normalizedMessage.contains('socketexception') ||
        normalizedMessage.contains('clientexception') ||
        normalizedMessage.contains('failed host lookup') ||
        normalizedMessage.contains('connection refused') ||
        normalizedMessage.contains('xmlhttprequest error')) {
      return 'Unable to connect. Check your internet connection and try again.';
    }
    return message;
  }

  void _showMessage(
    String message, {
    required bool isSuccess,
    bool isNeutral = false,
    ScaffoldMessengerState? messenger,
  }) {
    final targetMessenger = messenger ?? ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(targetMessenger.context).colorScheme;
    targetMessenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isNeutral
              ? colorScheme.inverseSurface
              : isSuccess
              ? const Color(0xFF2E7D32)
              : colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh profile',
                    onPressed: _isRefreshingProfile ? null : _refreshProfile,
                    icon: _isRefreshingProfile
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your profile and account security.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              _settingsCard(
                colorScheme: colorScheme,
                icon: Icons.person_outline_rounded,
                title: 'Profile Information',
                description: 'Update how your account is identified.',
                child: Form(
                  key: _profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _displayNameController,
                        maxLength: 100,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          hintText: 'What should we call you?',
                          prefixIcon: Icon(Icons.badge_outlined),
                          counterText: '',
                        ),
                        validator: (value) => (value?.trim().length ?? 0) > 100
                            ? 'Display name must be 100 characters or fewer'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        maxLength: 50,
                        textCapitalization: TextCapitalization.none,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                          counterText: '',
                        ),
                        validator: (value) {
                          final username = value?.trim() ?? '';
                          if (username.isEmpty) return 'Enter a username';
                          if (username.length > 50) {
                            return 'Username must be 50 characters or fewer';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _isUpdatingProfile ? null : _updateProfile,
                          icon: _isUpdatingProfile
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('Save profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _settingsCard(
                colorScheme: colorScheme,
                icon: Icons.shield_outlined,
                title: 'Security',
                description:
                    'Choose a strong password you have not used before.',
                child: Form(
                  key: _securityFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your current password'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: Icon(Icons.lock_reset_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter a new password';
                          }
                          if (value.length < 8) {
                            return 'Use at least 8 characters';
                          }
                          if (value == _currentPasswordController.text) {
                            return 'Choose a password different from the current one';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) =>
                            _isUpdatingPassword ? null : _updatePassword(),
                        decoration: const InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm your new password';
                          }
                          return value == _newPasswordController.text
                              ? null
                              : 'Passwords do not match';
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _isUpdatingPassword
                              ? null
                              : _updatePassword,
                          icon: _isUpdatingPassword
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_reset_rounded),
                          label: const Text('Update password'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _settingsCard(
                colorScheme: colorScheme,
                icon: Icons.palette_outlined,
                title: 'Appearance',
                description: 'Choose how Stockwise looks on this device.',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark Mode'),
                  value: context.watch<ThemeProvider>().isDarkMode,
                  onChanged: (enabled) =>
                      context.read<ThemeProvider>().setDarkMode(enabled),
                ),
              ),
              const SizedBox(height: 20),
              _settingsCard(
                colorScheme: colorScheme,
                icon: Icons.tune_rounded,
                title: 'Store Preferences',
                description: 'Set your currency and low-stock threshold.',
                child: Form(
                  key: _preferencesFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _currency,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          prefixIcon: Icon(Icons.currency_exchange_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(value: '₱', child: Text('₱')),
                          DropdownMenuItem(value: r'$', child: Text(r'$')),
                          DropdownMenuItem(value: '€', child: Text('€')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _currency = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lowStockThresholdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Global Low Stock Threshold',
                          prefixIcon: Icon(Icons.warning_amber_rounded),
                        ),
                        validator: (value) {
                          final threshold = int.tryParse(value?.trim() ?? '');
                          if (threshold == null ||
                              threshold < 0 ||
                              threshold > 2147483647) {
                            return 'Enter a whole number from 0 to 2147483647';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _settingsCard(
                colorScheme: colorScheme,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                description: 'Choose which updates you want to receive.',
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Low Stock Alerts'),
                      value: _notifyLowStock,
                      onChanged: (enabled) =>
                          setState(() => _notifyLowStock = enabled),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Weekly Summary'),
                      value: _notifyWeeklySummary,
                      onChanged: (enabled) =>
                          setState(() => _notifyWeeklySummary = enabled),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _isSavingPreferences
                            ? null
                            : _savePreferences,
                        icon: _isSavingPreferences
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save preferences'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _settingsCard(
                colorScheme: colorScheme,
                icon: Icons.manage_accounts_outlined,
                title: 'Account',
                description: 'Manage your signed-in account.',
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _confirmSignOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _settingsCard(
                colorScheme: colorScheme,
                icon: Icons.warning_amber_rounded,
                title: 'Danger Zone',
                description: 'These actions permanently remove inventory or account data.',
                danger: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: _isClearingInventory ? null : _clearInventory,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                      icon: _isClearingInventory
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Clear Inventory Data'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isDeletingAccount ? null : _deleteAccount,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                      icon: _isDeletingAccount
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_remove_outlined),
                      label: const Text('Delete Account'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsCard({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String description,
    required Widget child,
    bool danger = false,
  }) {
    return Card(
      shape: danger
          ? RoundedRectangleBorder(
              side: BorderSide(color: colorScheme.error, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: danger ? colorScheme.error : colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
