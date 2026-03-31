import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import 'main_shell.dart';

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
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
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
      backgroundColor: KuriftuColors.background,
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
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.92),
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
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: KuriftuColors.gold, width: 1.5),
                        ),
                        child: ClipOval(
                          child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Brand
                      Text(
                        'KURIFTU',
                        style: TextStyle(fontFamily: 'PlayfairDisplay', 
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: KuriftuColors.gold,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AFRICAN VILLAGE',
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: KuriftuColors.textSecondary,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Tagline
                      Text(
                        'Discover Culture\nThrough AI',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'PlayfairDisplay', 
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: KuriftuColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 280,
                        child: Text(
                          'Scan artifacts, hear their ancient stories, and collect pieces of living heritage.',
                          textAlign: TextAlign.center,
                          style: KuriftuTheme.bodyText.copyWith(fontSize: 15, height: 1.7),
                        ),
                      ),

                      // ── Cultural Heritage Section ──
                      const SizedBox(height: 40),
                      _buildDiamondDivider(),
                      const SizedBox(height: 32),
                      Text(
                        'Our Vision',
                        style: TextStyle(fontFamily: 'PlayfairDisplay', 
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: KuriftuColors.gold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Kuriftu African Village is a living museum celebrating the artistic heritage of 54 African nations. Each villa is a portal into a different culture \u2014 handcrafted furniture, woven textiles, and sacred objects sourced from master artisans across the continent. Our AI Cultural Whisperer bridges ancient tradition with modern technology, letting you scan any object and instantly hear its centuries-old story.',
                        textAlign: TextAlign.center,
                        style: KuriftuTheme.bodyText.copyWith(fontSize: 14, height: 1.8),
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
        Expanded(child: Container(height: 0.5, color: KuriftuColors.glassBorder)),
        const SizedBox(width: 16),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: KuriftuColors.gold,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Container(height: 0.5, color: KuriftuColors.glassBorder)),
      ],
    );
  }

  Widget _buildStatPills() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatPill(icon: LucideIcons.globe, label: '54 Nations'),
        const SizedBox(width: 12),
        _StatPill(icon: LucideIcons.layers, label: '200+ Artifacts'),
        const SizedBox(width: 12),
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
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: KuriftuColors.glassBorder, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: KuriftuColors.gold),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: KuriftuColors.textPrimary,
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

