import 'package:app/ui/auth/widgets/login_error_banner.dart';
import 'package:app/ui/auth/widgets/login_header.dart';
import 'package:flutter/material.dart';
import 'package:app/ui/auth/view_models/login_viewmodel.dart';
import 'package:app/ui/core/ui/content_column.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class LoginScreen extends StatefulWidget {
  final LoginViewModel viewModel;

  const LoginScreen({super.key, required this.viewModel});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<ShadFormState>();

  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.viewModel.signIn.addListener(_onSignInChanged);
  }

  void _onSignInChanged() {
    final command = widget.viewModel.signIn;
    if (!mounted) return;

    if (command.error) {
      final exception = command.exception;
      command.clearResult();
      setState(() => _error = widget.viewModel.messageFor(exception));
    } else if (command.running && _error != null) {
      setState(() => _error = null);
    }
  }

  void _submit() {
    final formState = _formKey.currentState!;

    if (!formState.saveAndValidate()) return;

    FocusScope.of(context).unfocus();

    widget.viewModel.signIn.execute((
      email: formState.getFieldValue('email'),
      password: formState.getFieldValue('password'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

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
                  final viewModel = widget.viewModel;

                  return ShadForm(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const LoginHeader(),

                        if (_error != null) ...[
                          ErrorBanner(message: _error!),
                          const SizedBox(height: 16),
                        ],

                        ShadInputFormField(
                          id: 'email',
                          enabled: !busy,
                          autofocus: true,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          placeholder: const Text('you@example.com'),
                          leading: const Icon(Icons.alternate_email, size: 20),
                          validator: viewModel.validator.validateEmail,
                        ),

                        const SizedBox(height: 12),
                        ShadInputFormField(
                          id: 'password',
                          enabled: !busy,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          placeholder: const Text('Password'),
                          leading: const Icon(Icons.lock_outline),
                          trailing: SizedBox.square(
                            dimension: 24,
                            child: OverflowBox(
                              maxWidth: 28,
                              maxHeight: 28,
                              child: ShadIconButton(
                                iconSize: 20,
                                padding: EdgeInsets.all(2),
                                icon: Icon(
                                  _obscurePassword
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.eye,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          validator: viewModel.validator.validatePassword,
                        ),

                        const SizedBox(height: 24),
                        ShadButton(
                          onPressed: busy ? null : _submit,
                          enabled: !busy,
                          leading: busy
                              ? SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primaryForeground,
                                  ),
                                )
                              : null,
                          child: const Text('Sign in'),
                        ),

                        const SizedBox(height: 12),
                        Text(
                          'Seeded demo accounts all use the password '
                          '“password-123”.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.blockquote.copyWith(
                            color: theme.colorScheme.primary,
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

  @override
  void dispose() {
    widget.viewModel.signIn.removeListener(_onSignInChanged);
    _formKey.currentState?.dispose();
    super.dispose();
  }
}
