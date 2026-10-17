import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/api_service.dart';
import '../widgets/jimatmy_ui.dart';
import '../widgets/mobile_content.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({required this.email, super.key});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscureNew = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final api = context.read<ApiService>();
    try {
      await api.resetPassword(
        email: _email.text.trim(),
        code: _code.text.trim(),
        newPassword: _newPassword.text,
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
          _submitting = false;
        });
      }
      return;
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.';
          _submitting = false;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context, true);
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    return valid ? null : context.l10n.invalidEmail;
  }

  String? _validateCode(String? value) {
    final code = value?.trim() ?? '';
    return RegExp(r'^[0-9]{6}$').hasMatch(code)
        ? null
        : context.l10n.invalidResetCode;
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';
    final strong =
        password.length >= 10 &&
        password.length <= 72 &&
        RegExp('[a-z]').hasMatch(password) &&
        RegExp('[A-Z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password);
    return strong ? null : context.l10n.weakPassword;
  }

  String? _validateConfirm(String? value) =>
      value == _newPassword.text ? null : context.l10n.passwordsMismatch;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.resetPasswordTitle)),
      body: MobileContent(
        safeArea: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const JimatMyLogoBadge(size: 68),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.resetPasswordTitle,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.resetPasswordSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enabled: !_submitting,
                    decoration: InputDecoration(
                      labelText: context.l10n.registeredEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                    maxLength: 6,
                    enabled: !_submitting,
                    decoration: InputDecoration(
                      labelText: context.l10n.resetCode,
                      counterText: '',
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                    validator: _validateCode,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _newPassword,
                    obscureText: _obscureNew,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    enabled: !_submitting,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: context.l10n.newPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscureNew
                            ? context.l10n.showPassword
                            : context.l10n.hidePassword,
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _obscureNew = !_obscureNew),
                        icon: Icon(
                          _obscureNew ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: _validateNewPassword,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: _obscureNew,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    enabled: !_submitting,
                    onFieldSubmitted: (_) => _submitting ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: context.l10n.confirmNewPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscureNew
                            ? context.l10n.showPassword
                            : context.l10n.hidePassword,
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _obscureNew = !_obscureNew),
                        icon: Icon(
                          _obscureNew ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: _validateConfirm,
                  ),
                  if (_errorMessage case final message?) ...[
                    const SizedBox(height: 14),
                    _ResetErrorBox(message: message),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      key: const ValueKey('reset-submit'),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.resetPasswordButton),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetErrorBox extends StatelessWidget {
  const _ResetErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: colors.onErrorContainer),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
