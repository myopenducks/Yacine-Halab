import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_branding.dart';
import '../auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController(text: 'admin');
  final _passwordCtrl = TextEditingController(text: 'admin123');
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).login(
            username: _usernameCtrl.text,
            password: _passwordCtrl.text,
          );
      if (mounted) {
        HapticFeedback.lightImpact();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = ref.watch(appStringsProvider);
    final authState = ref.watch(authNotifierProvider);
    final error = authState.error;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: MediaQuery.of(context).padding.top + 24,
          ),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),
                  _HeroBrand(isLight: isLight, subtitle: strings.inventoryAndSales),
                  const SizedBox(height: 44),
                  Text(
                    strings.welcomeBack,
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.signInPrompt,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isLight ? AppColors.gray500 : AppColors.gray400,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameCtrl,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocus);
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline),
                      hintText: strings.username,
                    ),
                    style: theme.textTheme.bodyLarge,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return strings.usernameRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    focusNode: _passwordFocus,
                    obscureText: _obscure,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      hintText: strings.password,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    style: theme.textTheme.bodyLarge,
                    validator: (v) {
                      if (v == null || v.isEmpty) return strings.passwordRequired;
                      if (v.length < 4) return 'At least 4 characters';
                      return null;
                    },
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(message: error),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : Text(strings.signIn),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () {
                              _usernameCtrl.text = 'admin';
                              _passwordCtrl.text = 'admin123';
                              _submit();
                            },
                      child: Text(strings.continueAsGuest),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Spacer(flex: 3),
                  const DevelopedByZiadFooter(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBrand extends StatelessWidget {
  const _HeroBrand({required this.isLight, required this.subtitle});

  final bool isLight;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isLight ? AppColors.primary : AppColors.accent,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.checkroom_rounded,
            size: 28,
            color: isLight ? AppColors.onPrimary : AppColors.dark,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Boutique Store', style: theme.textTheme.headlineMedium),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isLight ? AppColors.gray500 : AppColors.gray400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isLight ? AppColors.danger : AppColors.danger)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: isLight ? 0.3 : 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline,
                size: 18, color: isLight ? AppColors.danger : AppColors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isLight ? AppColors.gray900 : AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
