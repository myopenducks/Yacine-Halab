import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../auth_provider.dart';
import 'widgets/boutique_background_painter.dart';

/// Exact implementation of the luxury Boutique Inventory Login Screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _loading = false;

  static const Color _bgCream = Color(0xFFFBF8F1);
  static const Color _darkEspresso = Color(0xFF2D1E18);
  static const Color _mutedBrown = Color(0xFF6E5D54);
  static const Color _hintBrown = Color(0xFF8C7A70);

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

  Future<void> _loginAsGuest() async {
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).loginGuest();
      if (mounted) {
        HapticFeedback.lightImpact();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final authState = ref.watch(authNotifierProvider);
    final error = authState.error;

    return Scaffold(
      backgroundColor: _bgCream,
      body: Stack(
        children: [
          // ── Background Layer: Line-art Boutique Illustrations ──
          const Positioned.fill(
            child: CustomPaint(
              painter: BoutiqueBackgroundPainter(
                strokeColor: _mutedBrown,
                opacity: 0.38,
              ),
            ),
          ),

          // ── Interactive UI Content Layer ──
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 120),

                              // ── Header Typography ──
                              Text(
                                'BOUTIQUE\nINVENTORY',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.8,
                                  color: _darkEspresso,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Management & Sales Suite',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: _mutedBrown,
                                  letterSpacing: 0.2,
                                ),
                              ),

                              const SizedBox(height: 48),

                              // ── Username Input Field ──
                              _BoutiqueTextField(
                                controller: _usernameCtrl,
                                hintText: strings.username,
                                prefixIcon: Icons.edit_outlined,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                onFieldSubmitted: (_) {
                                  _passwordFocus.requestFocus();
                                },
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return strings.usernameRequired;
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),

                              // ── Password Input Field ──
                              _BoutiqueTextField(
                                controller: _passwordCtrl,
                                focusNode: _passwordFocus,
                                hintText: '••••••••',
                                prefixIcon: Icons.vpn_key_outlined,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _submit(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _mutedBrown,
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return strings.passwordRequired;
                                  }
                                  if (v.length < 4) {
                                    return strings.isFrench
                                        ? 'Au moins 4 caractères'
                                        : 'At least 4 characters';
                                  }
                                  return null;
                                },
                              ),

                              // ── Error Banner (if any) ──
                              if (error != null) ...[
                                const SizedBox(height: 14),
                                _BoutiqueErrorBanner(message: error),
                              ],

                              const SizedBox(height: 24),

                              // ── SIGN IN Button ──
                              _CopperGradientButton(
                                label: strings.isFrench ? 'SE CONNECTER' : 'SIGN IN',
                                loading: _loading,
                                onPressed: _loading ? null : _submit,
                              ),

                              const SizedBox(height: 16),

                              // ── Continue as Guest Link ──
                              Center(
                                child: TextButton(
                                  onPressed: _loading ? null : _loginAsGuest,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    foregroundColor: _darkEspresso,
                                  ),
                                  child: Text(
                                    strings.isFrench
                                        ? 'Continuer en tant qu\'invité'
                                        : 'Continue as Guest',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _darkEspresso,
                                      decoration: TextDecoration.underline,
                                      decorationColor: _darkEspresso,
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // ── Bottom Left Footer Credit ──
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  strings.isFrench
                                      ? 'Développé par Ziad'
                                      : 'Developed by Ziad',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _hintBrown,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _BoutiqueTextField extends StatelessWidget {
  const _BoutiqueTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.focusNode,
    this.obscureText = false,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  static const Color _darkEspresso = Color(0xFF2D1E18);
  static const Color _borderBrown = Color(0xFF7E6C62);
  static const Color _hintBrown = Color(0xFF8C7A70);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: GoogleFonts.outfit(
        color: _darkEspresso,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: _darkEspresso,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.outfit(
          color: _hintBrown,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: _borderBrown,
          size: 19,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderBrown, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderBrown, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkEspresso, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
      ),
    );
  }
}

class _CopperGradientButton extends StatelessWidget {
  const _CopperGradientButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7A3B2E),
            Color(0xFF9E5240),
            Color(0xFF7A3B2E),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A3B2E).withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _BoutiqueErrorBanner extends StatelessWidget {
  const _BoutiqueErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.35),
          width: 1.1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
