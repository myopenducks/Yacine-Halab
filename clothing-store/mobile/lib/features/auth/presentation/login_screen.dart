import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../auth_provider.dart';
import 'widgets/boutique_background_painter.dart';

/// Pixel-perfect luxury Boutique Inventory Login Screen.
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

  // ── Precise Color Palette ──
  static const Color _bgCream = Color(0xFFFBF8F1);
  static const Color _deepEspresso = Color(0xFF2C1A11);

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
          // ── Layer 1: Background Color (Canvas Area) ──
          const Positioned.fill(
            child: ColoredBox(color: _bgCream),
          ),

          // ── Layer 2: Exact Line-Art Boutique Background Pattern + Vector Assets ──
          const Positioned.fill(
            child: CustomPaint(
              painter: BoutiqueBackgroundPainter(
                strokeColor: _deepEspresso,
                opacity: 0.13,
              ),
            ),
          ),

          // Top-right boutique garment SVG
          Positioned(
            top: 75,
            right: 18,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.12,
                child: SvgPicture.asset(
                  'assets/icon/Vector.svg',
                  width: 72,
                  height: 72,
                  colorFilter: const ColorFilter.mode(
                    _deepEspresso,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // Top boutique hanger SVG
          Positioned(
            top: 52,
            right: 105,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.11,
                child: SvgPicture.asset(
                  'assets/icon/Group (1).svg',
                  width: 65,
                  height: 40,
                  colorFilter: const ColorFilter.mode(
                    _deepEspresso,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // Bottom-left authentic boutique trousers SVG (Vector (2).svg)
          Positioned(
            bottom: 45,
            left: 20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.12,
                child: SvgPicture.asset(
                  'assets/icon/Vector (2).svg',
                  width: 46,
                  height: 94,
                  colorFilter: const ColorFilter.mode(
                    _deepEspresso,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // Bottom-right authentic boutique sock/footwear SVG (Vector (1).svg)
          Positioned(
            bottom: 45,
            right: 24,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.12,
                child: SvgPicture.asset(
                  'assets/icon/Vector (1).svg',
                  width: 52,
                  height: 72,
                  colorFilter: const ColorFilter.mode(
                    _deepEspresso,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // Bottom boutique hanger SVG
          Positioned(
            bottom: 85,
            left: 135,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.11,
                child: SvgPicture.asset(
                  'assets/icon/Group (2).svg',
                  width: 58,
                  height: 40,
                  colorFilter: const ColorFilter.mode(
                    _deepEspresso,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 3: Interactive UI Elements ──
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 110),

                              // ── Header Typography ──
                              Text(
                                'BOUTIQUE\nINVENTORY',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 34.0,
                                  fontWeight: FontWeight.bold,
                                  color: _deepEspresso,
                                  height: 1.12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Management & Sales Suite',
                                style: GoogleFonts.inter(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w400,
                                  color: _deepEspresso,
                                  letterSpacing: 0.2,
                                ),
                              ),

                              const SizedBox(height: 52),

                              // ── Username Input Field (Quill Icon) ──
                              _BoutiqueTextField(
                                controller: _usernameCtrl,
                                hintText: strings.isFrench ? strings.username : 'username',
                                prefixIconWidget: const QuillFeatherIcon(
                                  color: _deepEspresso,
                                  size: 18,
                                ),
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

                              const SizedBox(height: 16),

                              // ── Password Input Field (Key Icon + Eye Toggle) ──
                              _BoutiqueTextField(
                                controller: _passwordCtrl,
                                focusNode: _passwordFocus,
                                hintText: '••••••••',
                                prefixIconWidget: const Icon(
                                  Icons.vpn_key_outlined,
                                  color: _deepEspresso,
                                  size: 19,
                                ),
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _submit(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _deepEspresso.withValues(alpha: 0.7),
                                    size: 20,
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

                              const SizedBox(height: 26),

                              // ── SIGN IN Button (Metallic Copper Gradient) ──
                              _CopperGradientButton(
                                label: strings.isFrench ? 'SE CONNECTER' : 'SIGN IN',
                                loading: _loading,
                                onPressed: _loading ? null : _submit,
                              ),

                              const SizedBox(height: 18),

                              // ── Continue as Guest Underlined Link ──
                              Center(
                                child: TextButton(
                                  onPressed: _loading ? null : _loginAsGuest,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    foregroundColor: _deepEspresso,
                                  ),
                                  child: Text(
                                    strings.isFrench
                                        ? 'Continuer en tant qu\'invité'
                                        : 'Continue as Guest',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                      color: _deepEspresso,
                                      decoration: TextDecoration.underline,
                                      decorationColor: _deepEspresso,
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
                                  style: GoogleFonts.inter(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w400,
                                    color: _deepEspresso.withValues(alpha: 0.65),
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

/// Custom Quill / Feather Icon Vector Widget.
class QuillFeatherIcon extends StatelessWidget {
  const QuillFeatherIcon({
    super.key,
    this.color = const Color(0xFF2C1A11),
    this.size = 20,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: CustomPaint(
          size: Size(size, size),
          painter: _QuillPainter(color: color),
        ),
      ),
    );
  }
}

class _QuillPainter extends CustomPainter {
  const _QuillPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Central quill shaft
    final pShaft = Path()
      ..moveTo(w * 0.20, h * 0.85)
      ..cubicTo(w * 0.42, h * 0.60, w * 0.65, h * 0.38, w * 0.82, h * 0.18);
    canvas.drawPath(pShaft, paint);

    // Quill feather outer vanes
    final pVane = Path()
      ..moveTo(w * 0.82, h * 0.18)
      ..cubicTo(w * 0.58, h * 0.12, w * 0.32, h * 0.28, w * 0.30, h * 0.55)
      ..lineTo(w * 0.38, h * 0.52)
      ..moveTo(w * 0.82, h * 0.18)
      ..cubicTo(w * 0.86, h * 0.44, w * 0.68, h * 0.66, w * 0.45, h * 0.66)
      ..lineTo(w * 0.48, h * 0.60);
    canvas.drawPath(pVane, paint);
  }

  @override
  bool shouldRepaint(covariant _QuillPainter oldDelegate) => false;
}

class _BoutiqueTextField extends StatelessWidget {
  const _BoutiqueTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIconWidget,
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
  final Widget prefixIconWidget;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  static const Color _deepEspresso = Color(0xFF2C1A11);
  static const Color _mutedBorder = Color(0xFFE0D8D0);
  static const Color _hintColor = Color(0xFF8C7A70);

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
      style: GoogleFonts.inter(
        color: _deepEspresso,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: _deepEspresso,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: _hintColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: prefixIconWidget,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 46,
          minHeight: 24,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: _mutedBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: _mutedBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: _deepEspresso, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
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
        borderRadius: BorderRadius.circular(30.0),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7A3B2E),
            Color(0xFF9E5240),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A3B2E).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30.0),
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.06),
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
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
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
          width: 1.0,
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
              style: GoogleFonts.inter(
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
