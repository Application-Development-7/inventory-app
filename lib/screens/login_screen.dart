import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'register_screen.dart';
import '../services/auth_service.dart';
import '../widgets/auth_branding_panel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController(text: 'admin');
  final _pass = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().login(_user.text.trim(), _pass.text);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRegister() async {
    final username = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const RegisterScreen()));
    if (!mounted || username == null) return;
    setState(() => _user.text = username);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created. Sign in to continue.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inheritedTheme = Theme.of(context);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFA78BFA),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFFA78BFA),
          secondary: const Color(0xFFF472B6),
          surface: Colors.white,
        );
    final theme = inheritedTheme.copyWith(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      inputDecorationTheme: inheritedTheme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Color(0xFF5F5B66)),
        hintStyle: const TextStyle(color: Color(0xFF85818C)),
        prefixIconColor: const Color(0xFF706B77),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2DFE6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFA78BFA), width: 1.5),
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  children: [
                    const Expanded(child: AuthBrandingPanel()),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 32,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: _buildLoginForm(theme, colorScheme),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _buildLoginForm(theme, colorScheme),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(ThemeData theme, ColorScheme colorScheme) {
    final mutedColor = colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WELCOME BACK',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Sign in to Stockwise',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF211F2B),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'Enter your details to access your inventory workspace.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: mutedColor,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _user,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'Username',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2DFE6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFA78BFA),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pass,
          obscureText: _obscurePassword,
          autofillHints: const [],
          onSubmitted: (_) => _loading ? null : _submit(),
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2DFE6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFA78BFA),
                width: 1.5,
              ),
            ),
            suffixIcon: TextButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              child: Text(_obscurePassword ? 'Show' : 'Hide'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 360) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRememberMe(theme, colorScheme),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildForgotPasswordButton(),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: _buildRememberMe(theme, colorScheme)),
                _buildForgotPasswordButton(),
              ],
            );
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF5D0CB)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFB53F38)),
            ),
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sign in'),
                      SizedBox(width: 9),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _loading ? null : _openRegister,
            child: const Text('Create an account'),
          ),
        ),
      ],
    );
  }

  Widget _buildRememberMe(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: _rememberMe,
            onChanged: (value) => setState(() => _rememberMe = value ?? false),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Flexible(
            child: Text(
              'Remember me',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF333039),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: const Text('Forgot password?'),
    );
  }
}
