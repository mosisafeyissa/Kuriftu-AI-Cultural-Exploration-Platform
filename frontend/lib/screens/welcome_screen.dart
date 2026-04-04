import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import 'main_shell.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    final auth = context.read<AuthProvider>();
    final Widget destination = auth.isAuthenticated ? const MainShell() : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
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
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.92),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.06),

                      // Logo
                      Image.asset(
                        'assets/images/logo_white.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),

                      // Brand
                      Text(
                        'AFRILENS',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AfrilensColors.gold,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CULTURAL EXPLORATION',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AfrilensColors.textSecondary,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Tagline
                      Text(
                        'Discover Culture\nThrough AI',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AfrilensColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 280,
                        child: Text(
                          'Scan artifacts, hear their ancient stories, and collect pieces of living heritage.',
                          textAlign: TextAlign.center,
                          style: AfrilensTheme.bodyText.copyWith(fontSize: 15, height: 1.7),
                        ),
                      ),

                      // ── Cultural Heritage Section ──
                      const SizedBox(height: 40),
                      _buildDiamondDivider(),
                      const SizedBox(height: 32),
                      Text(
                        'Our Vision',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AfrilensColors.gold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Afrilens is a living platform celebrating the artistic heritage of 54 African nations. Each artifact is a portal into a different culture \u2014 handcrafted furniture, woven textiles, and sacred objects sourced from master artisans across the continent. Our AI Cultural Whisperer bridges ancient tradition with modern technology, letting you scan any object and instantly hear its centuries-old story.',
                        textAlign: TextAlign.center,
                        style: AfrilensTheme.bodyText.copyWith(fontSize: 14, height: 1.8),
                      ),

                      const SizedBox(height: 28),
                      _buildStatPills(),

                      // CTA
                      const SizedBox(height: 44),
                      SizedBox(
                        width: double.infinity,
                        child: GoldButton(
                          text: 'BEGIN YOUR JOURNEY',
                          icon: LucideIcons.sparkles,
                          onPressed: _navigateToHome,
                        ),
                      ),
                      const SizedBox(height: 48),
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

  Widget _buildDiamondDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 0.5, color: AfrilensColors.glassBorder)),
        const SizedBox(width: 16),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AfrilensColors.gold,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Container(height: 0.5, color: AfrilensColors.glassBorder)),
      ],
    );
  }


  Widget _buildStatPills() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatPill(icon: LucideIcons.globe, label: '54 Nations'),
        _StatPill(icon: LucideIcons.layers, label: '200+ Artifacts'),
        _StatPill(icon: LucideIcons.sparkles, label: 'AI-Powered'),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AfrilensColors.glassBorder, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AfrilensColors.gold),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AfrilensColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
