import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirm: _confirmPasswordController.text,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (success && mounted) {
      context.read<NotificationProvider>().onAuthStateChanged(true);
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
        (_) => false,
      );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        color: AfrilensColors.textMuted,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: AfrilensColors.gold, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AfrilensColors.glassBorder, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AfrilensColors.glassBorder, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AfrilensColors.gold, width: 1),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1),
      ),
      errorStyle: GoogleFonts.inter(fontSize: 11, color: Colors.red.shade300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AfrilensColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/AFRICA.jpg', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.95),
                ],
              ),
            ),
          ),


          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.04),

                      // Back button row
                      Row(
                        children: [
                          GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.08),
                                  border: Border.all(
                                      color: AfrilensColors.glassBorder,
                                      width: 0.5),
                                ),
                                child: const Icon(
                                  LucideIcons.arrowLeft,
                                  color: AfrilensColors.textPrimary,
                                  size: 18,
                                ),
                              ),

                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Logo
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AfrilensColors.gold, width: 1.5),
                        ),
                        child: ClipOval(
                          child: Image.asset('assets/images/logo.png',
                              fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'AFRILENS',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AfrilensColors.gold,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JOIN THE EXPERIENCE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AfrilensColors.textSecondary,
                          letterSpacing: 3,
                        ),
                      ),


                      const SizedBox(height: 28),

                      // ── Glass Card Form ──
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AfrilensColors.glassBorder,
                                width: 0.5,
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Account',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: AfrilensColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Begin your cultural exploration journey',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AfrilensColors.textMuted,
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Full Name
                                  TextFormField(
                                    controller: _fullNameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    style: GoogleFonts.inter(
                                      color: AfrilensColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                    decoration: _inputDecoration(
                                      label: 'Full Name',
                                      icon: LucideIcons.user,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Full name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Email
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: GoogleFonts.inter(
                                      color: AfrilensColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                    decoration: _inputDecoration(
                                      label: 'Email Address',
                                      icon: LucideIcons.mail,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!v.contains('@') ||
                                          !v.contains('.')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Phone
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.inter(
                                      color: AfrilensColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                    decoration: _inputDecoration(
                                      label: 'Phone (optional)',
                                      icon: LucideIcons.phone,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Password
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: GoogleFonts.inter(
                                      color: AfrilensColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                    decoration: _inputDecoration(
                                      label: 'Password',
                                      icon: LucideIcons.lock,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? LucideIcons.eyeOff
                                              : LucideIcons.eye,
                                          color: AfrilensColors.textMuted,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (v.length < 8) {
                                        return 'Minimum 8 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Confirm Password
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirm,
                                    style: GoogleFonts.inter(
                                      color: AfrilensColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                    decoration: _inputDecoration(
                                      label: 'Confirm Password',
                                      icon: LucideIcons.shieldCheck,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm
                                              ? LucideIcons.eyeOff
                                              : LucideIcons.eye,
                                          color: AfrilensColors.textMuted,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscureConfirm =
                                                !_obscureConfirm),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Error Message
                                  Consumer<AuthProvider>(
                                    builder: (_, auth, __) {
                                      if (auth.errorMessage == null) {
                                        return const SizedBox.shrink();
                                      }
                                      return Container(
                                        width: double.infinity,
                                        margin:
                                            const EdgeInsets.only(bottom: 18),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.red
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.red
                                                .withOpacity(0.3),
                                          ),
                                        ),

                                        child: Row(
                                          children: [
                                            Icon(LucideIcons.alertCircle,
                                                color: Colors.red.shade300,
                                                size: 18),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                auth.errorMessage!,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: Colors.red.shade300,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                  // Register Button
                                  Consumer<AuthProvider>(
                                    builder: (_, auth, __) {
                                      return SizedBox(
                                        width: double.infinity,
                                        child: auth.isLoading
                                            ? Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: AfrilensColors.gold,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : GoldButton(
                                                text: 'CREATE ACCOUNT',
                                                icon: LucideIcons.sparkles,
                                                onPressed: _handleRegister,
                                              ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AfrilensColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AfrilensColors.gold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.04),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
