import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _showPasswordForm = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startEditing() {
    final auth = context.read<AuthProvider>();
    _nameController.text = auth.user?.fullName ?? '';
    _phoneController.text = auth.user?.phone ?? '';
    setState(() => _isEditing = true);
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (success && mounted) {
      setState(() => _isEditing = false);
      _showSnack('Profile updated successfully');
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnack('Passwords do not match', isError: true);
      return;
    }
    if (_newPasswordController.text.length < 8) {
      _showSnack('Password must be at least 8 characters', isError: true);
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(
      oldPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
      newPasswordConfirm: _confirmPasswordController.text,
    );
    if (success && mounted) {
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _showPasswordForm = false);
      _showSnack('Password changed successfully');
    } else if (mounted && auth.errorMessage != null) {
      _showSnack(auth.errorMessage!, isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: isError
            ? Colors.red.withOpacity(0.85)
            : Colors.green.withOpacity(0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AfrilensColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.playfairDisplay(
            color: AfrilensColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(color: AfrilensColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AfrilensColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign Out',
                style: GoogleFonts.inter(
                    color: Colors.red.shade400, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const WelcomeScreen(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
          ),
          (_) => false,
        );
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          GoogleFonts.inter(color: AfrilensColors.textMuted, fontSize: 14),
      prefixIcon: Icon(icon, color: AfrilensColors.gold, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AfrilensColors.glassBorder, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AfrilensColors.glassBorder, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AfrilensColors.gold, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AfrilensColors.background,
      body: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          final user = auth.user;
          if (user == null) {
            return const Center(
              child: CircularProgressIndicator(color: AfrilensColors.gold),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AfrilensColors.background,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AfrilensColors.gold.withOpacity(0.15),
                              AfrilensColors.background,
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 40),
                            // Avatar
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AfrilensColors.gold,
                                    AfrilensColors.goldDark,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AfrilensColors.gold.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(user.fullName, user.email),
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: AfrilensColors.background,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName
                                  : 'Explorer',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AfrilensColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AfrilensColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Profile Info / Edit Card ──
                    _buildGlassCard(
                      child: _isEditing
                          ? _buildEditForm(auth)
                          : _buildProfileInfo(user),
                    ),

                    const SizedBox(height: 16),

                    // ── Change Password ──
                    _buildGlassCard(
                      child: _showPasswordForm
                          ? _buildPasswordForm(auth)
                          : _buildPasswordButton(),
                    ),

                    const SizedBox(height: 16),

                    // ── Account Info ──
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            icon: LucideIcons.calendar,
                            label: 'Member Since',
                            value: _formatDate(user.dateJoined),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Logout Button ──
                    GestureDetector(
                      onTap: _handleLogout,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.4),
                            width: 1,
                          ),
                          color: Colors.red.withOpacity(0.08),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.logOut,
                                color: Colors.red.shade400, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'SIGN OUT',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade400,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AfrilensColors.glassBorder, width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildProfileInfo(user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Profile',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AfrilensColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: _startEditing,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AfrilensColors.gold.withOpacity(0.5)),
                  color: AfrilensColors.gold.withOpacity(0.08),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.edit3,
                        color: AfrilensColors.gold, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Edit',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AfrilensColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildInfoRow(
          icon: LucideIcons.user,
          label: 'Full Name',
          value: user.fullName.isNotEmpty ? user.fullName : 'Not set',
        ),
        const SizedBox(height: 14),
        _buildInfoRow(
          icon: LucideIcons.mail,
          label: 'Email',
          value: user.email,
        ),
        const SizedBox(height: 14),
        _buildInfoRow(
          icon: LucideIcons.phone,
          label: 'Phone',
          value: user.phone.isNotEmpty ? user.phone : 'Not set',
        ),
      ],
    );
  }

  Widget _buildEditForm(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Edit Profile',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AfrilensColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _isEditing = false),
              child: const Icon(LucideIcons.x,
                  color: AfrilensColors.textMuted, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _nameController,
          style:
              GoogleFonts.inter(color: AfrilensColors.textPrimary, fontSize: 15),
          decoration: _inputDecoration(label: 'Full Name', icon: LucideIcons.user),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style:
              GoogleFonts.inter(color: AfrilensColors.textPrimary, fontSize: 15),
          decoration: _inputDecoration(label: 'Phone', icon: LucideIcons.phone),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: auth.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AfrilensColors.gold, strokeWidth: 2))
              : GoldButton(
                  text: 'SAVE CHANGES',
                  icon: LucideIcons.check,
                  onPressed: _saveProfile,
                ),
        ),
      ],
    );
  }

  Widget _buildPasswordButton() {
    return GestureDetector(
      onTap: () => setState(() => _showPasswordForm = true),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AfrilensColors.gold.withOpacity(0.1),
            ),
            child: const Icon(LucideIcons.key, color: AfrilensColors.gold, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Change Password',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AfrilensColors.textPrimary,
              ),
            ),
          ),
          const Icon(LucideIcons.chevronRight,
              color: AfrilensColors.textMuted, size: 18),
        ],
      ),
    );
  }

  Widget _buildPasswordForm(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Change Password',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AfrilensColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _showPasswordForm = false),
              child: const Icon(LucideIcons.x,
                  color: AfrilensColors.textMuted, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _oldPasswordController,
          obscureText: true,
          style:
              GoogleFonts.inter(color: AfrilensColors.textPrimary, fontSize: 15),
          decoration: _inputDecoration(
              label: 'Current Password', icon: LucideIcons.lock),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _newPasswordController,
          obscureText: true,
          style:
              GoogleFonts.inter(color: AfrilensColors.textPrimary, fontSize: 15),
          decoration:
              _inputDecoration(label: 'New Password', icon: LucideIcons.key),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          style:
              GoogleFonts.inter(color: AfrilensColors.textPrimary, fontSize: 15),
          decoration: _inputDecoration(
              label: 'Confirm New Password', icon: LucideIcons.shieldCheck),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: auth.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AfrilensColors.gold, strokeWidth: 2))
              : GoldButton(
                  text: 'UPDATE PASSWORD',
                  icon: LucideIcons.check,
                  onPressed: _changePassword,
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AfrilensColors.gold, size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AfrilensColors.textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AfrilensColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getInitials(String name, String email) {
    if (name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return parts.first[0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
