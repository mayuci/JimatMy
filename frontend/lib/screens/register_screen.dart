import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../widgets/jimatmy_ui.dart';
import '../widgets/mobile_content.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  final _confirmPasswordFieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    final error = await context.read<AuthProvider>().register(
      _name.text,
      _email.text,
      _password.text,
    );
    if (error == null && mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.createAccountShort)),
      body: MobileContent(
        safeArea: true,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            24,
            keyboardVisible ? 10 : 24,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) => AutofillGroup(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!keyboardVisible) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const JimatMyLogoBadge(size: 68),
                              const SizedBox(width: 12),
                              Text(
                                'JimatMY',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: JimatMyColors.deepGreen,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        context.l10n.registerTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: JimatMyColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.registerSubtitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: InputDecoration(
                          labelText: context.l10n.name,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        onChanged: (_) => auth.clearError(),
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? context.l10n.enterName
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: context.l10n.email,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        autocorrect: false,
                        onChanged: (_) => auth.clearError(),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.newPassword],
                        onChanged: (_) => _onPasswordChanged(auth),
                        decoration: InputDecoration(
                          labelText: context.l10n.password,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? context.l10n.showPassword
                                : context.l10n.hidePassword,
                            onPressed: auth.isLoading
                                ? null
                                : () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 6),
                      _PasswordGuidance(password: _password.text),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: _confirmPasswordFieldKey,
                        controller: _confirmPassword,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.newPassword],
                        onChanged: (_) => auth.clearError(),
                        onFieldSubmitted: (_) =>
                            auth.isLoading ? null : _submit(),
                        decoration: InputDecoration(
                          labelText: context.l10n.confirmPassword,
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirm
                                ? context.l10n.showPassword
                                : context.l10n.hidePassword,
                            onPressed: auth.isLoading
                                ? null
                                : () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) => value == _password.text
                            ? null
                            : context.l10n.passwordsMismatch,
                      ),
                      if (auth.errorMessage case final message?) ...[
                        const SizedBox(height: 14),
                        _RegisterErrorMessage(message: message),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          key: const ValueKey('register-submit'),
                          onPressed: auth.isLoading ? null : _submit,
                          child: auth.isLoading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(context.l10n.createAccountShort),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : () => Navigator.maybePop(context),
                        child: Text(context.l10n.backToLogin),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPasswordChanged(AuthProvider auth) {
    setState(() {});
    auth.clearError();
    if (_confirmPassword.text.isNotEmpty) {
      _confirmPasswordFieldKey.currentState?.validate();
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
        ? null
        : context.l10n.invalidEmail;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    final strong =
        password.length >= 10 &&
        password.contains(RegExp('[A-Z]')) &&
        password.contains(RegExp('[a-z]')) &&
        password.contains(RegExp(r'\d'));
    return strong ? null : context.l10n.weakPassword;
  }
}

class _PasswordGuidance extends StatelessWidget {
  const _PasswordGuidance({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          context.l10n.passwordHelper,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }
    final lengthOk = password.length >= 10;
    final upperOk = password.contains(RegExp('[A-Z]'));
    final lowerOk = password.contains(RegExp('[a-z]'));
    final numberOk = password.contains(RegExp(r'\d'));
    final strong = lengthOk && upperOk && lowerOk && numberOk;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PasswordRuleRow(
          label: context.l10n.passwordRequirementLength,
          satisfied: lengthOk,
        ),
        const SizedBox(height: 2),
        _PasswordRuleRow(
          label: context.l10n.passwordRequirementUpper,
          satisfied: upperOk,
        ),
        const SizedBox(height: 2),
        _PasswordRuleRow(
          label: context.l10n.passwordRequirementLower,
          satisfied: lowerOk,
        ),
        const SizedBox(height: 2),
        _PasswordRuleRow(
          label: context.l10n.passwordRequirementNumber,
          satisfied: numberOk,
        ),
        if (strong) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 16,
                color: JimatMyColors.green,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.passwordStrong,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: JimatMyColors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PasswordRuleRow extends StatelessWidget {
  const _PasswordRuleRow({required this.label, required this.satisfied});

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    final color = satisfied
        ? JimatMyColors.green
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          satisfied ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: satisfied ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _RegisterErrorMessage extends StatelessWidget {
  const _RegisterErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline,
          size: 20,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
      ],
    ),
  );
}
