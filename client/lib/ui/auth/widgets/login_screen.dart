import 'package:flutter/material.dart';

import 'package:app/data/services/api/api_exception.dart';
import 'package:app/ui/auth/view_models/login_viewmodel.dart';
import 'package:app/ui/core/ui/content_column.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.viewModel});

  final LoginViewModel viewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  String? _error;

  @override
  void initState() {
    super.initState();
    widget.viewModel.signIn.addListener(_onSignInChanged);
  }

  @override
  void dispose() {
    widget.viewModel.signIn.removeListener(_onSignInChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onSignInChanged() {
    final command = widget.viewModel.signIn;
    if (!mounted) return;

    if (command.error) {
      final exception = command.exception;
      // Consume the result so the same failure is not reported twice.
      command.clearResult();
      setState(() => _error = _messageFor(exception));
      // Wrong credentials means the password is what needs fixing.
      _passwordController.clear();
      _passwordFocus.requestFocus();
    } else if (command.running && _error != null) {
      setState(() => _error = null);
    }
  }

  String _messageFor(Exception? exception) => switch (exception) {
    HttpException(:final isUnauthorized) when isUnauthorized =>
      'Incorrect email or password.',
    final Exception error => messageFor(error),
    null => 'Could not sign in.',
  };

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    widget.viewModel.signIn.execute((
      email: _emailController.text,
      password: _passwordController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ContentColumn(
              maxWidth: 380,
              child: ListenableBuilder(
                listenable: widget.viewModel.signIn,
                builder: (context, _) {
                  final busy = widget.viewModel.signIn.running;

                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.support_agent,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 20),
                        Text('IT Support', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to raise and track requests.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),

                        if (_error != null) ...[
                          _ErrorBanner(message: _error!),
                          const SizedBox(height: 16),
                        ],

                        TextFormField(
                          controller: _emailController,
                          enabled: !busy,
                          autofocus: true,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@example.com',
                            prefixIcon: Icon(Icons.alternate_email, size: 20),
                          ),
                          validator: (value) =>
                              (value ?? '').trim().contains('@')
                              ? null
                              : 'Enter your work email address.',
                          onFieldSubmitted: (_) =>
                              _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          enabled: !busy,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword ? 'Show' : 'Hide',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) => (value ?? '').isEmpty
                              ? 'Enter your password.'
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 24),

                        FilledButton(
                          onPressed: busy ? null : _submit,
                          child: busy
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Sign in'),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Seeded demo accounts all use the password '
                          '“password-123”.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // Tinted rather than solid: an error should read as urgent without
        // becoming the brightest thing on a dark screen.
        color: theme.colorScheme.error.withValues(alpha: 0.12),
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
