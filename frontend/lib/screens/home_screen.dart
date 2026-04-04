import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/artifact_card.dart';
import '../widgets/gold_button.dart';
import '../services/api_service.dart';
import '../models/artifact.dart';
import '../providers/notification_provider.dart';
import '../models/app_notification.dart';
import 'main_shell.dart';
import 'villas_screen.dart';
import 'artifact_detail_screen.dart';
import 'qr_scan_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  List<Artifact> _featured = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final featured = await ApiService.getFeaturedArtifacts();
      if (mounted) {
        setState(() {
          _featured = featured;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[HomeScreen] Load error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _switchToScanTab() {
    context.findAncestorStateOfType<MainShellState>()?.switchToTab(1);
  }

  void _openVillas() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const VillasScreen()));
  }

  void _showNotificationSheet(BuildContext context) {
    final notifProvider = context.read<NotificationProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
            decoration: BoxDecoration(
              color: AfrilensColors.surface.withOpacity(0.92),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: AfrilensColors.glassBorder, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AfrilensColors.textMuted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AfrilensColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          notifProvider.markAllRead();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Mark All Read',
                          style: AfrilensTheme.goldAccent.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AfrilensColors.glassBorder, height: 1),
                Flexible(
                  child: ChangeNotifierProvider.value(
                    value: notifProvider,
                    child: Consumer<NotificationProvider>(
                      builder: (context, notif, _) {
                        final items = notif.notifications;
                        if (items.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              'No notifications yet',
                              style: AfrilensTheme.bodyText.copyWith(color: AfrilensColors.textMuted),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: AfrilensColors.glassBorder,
                            height: 1,
                            indent: 68,
                          ),
                          itemBuilder: (context, index) => _NotificationTile(notification: items[index]),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AfrilensColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/villa_4.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.82)),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildHeroSection()),
              SliverToBoxAdapter(child: _buildCulturalJourneyCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: _buildActionButtons()),
              SliverToBoxAdapter(child: _buildFeaturedSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AfrilensColors.gold.withOpacity(0.6), width: 1),
            ),
            child: ClipOval(
              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'AfriLens',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AfrilensColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: AfrilensColors.glassBorder, width: 0.5),
              ),
              child: const Icon(LucideIcons.user, size: 18, color: AfrilensColors.textPrimary),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Consumer<NotificationProvider>(
          builder: (context, notif, _) {
            return GestureDetector(
              onTap: () => _showNotificationSheet(context),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: AfrilensColors.glassBorder, width: 0.5),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(LucideIcons.bell, size: 18, color: AfrilensColors.textPrimary),
                      if (notif.unreadCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AfrilensColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover',
            style: GoogleFonts.playfairDisplay(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: AfrilensColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'African Heritage',
            style: GoogleFonts.playfairDisplay(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: AfrilensColors.gold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan objects around you to unlock centuries of cultural stories powered by AI.',
            style: AfrilensTheme.bodyText.copyWith(fontSize: 15, height: 1.7),
          ),
        ],
      ),
    );
  }

  void _openCulturalJourney() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScanScreen()));
  }

  Widget _buildCulturalJourneyCard() {
    return GestureDetector(
      onTap: _openCulturalJourney,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [AfrilensColors.goldDark, AfrilensColors.gold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AfrilensColors.gold.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                LucideIcons.sparkles,
                size: 160,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'CULTURAL JOURNEY',
                          style: AfrilensTheme.labelText.copyWith(
                            color: Colors.white,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your Personal AI Tour Guide',
                          style: AfrilensTheme.headlineSerif.copyWith(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.qrCode, color: AfrilensColors.gold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: GoldButton(
              text: 'EXPLORE VILLAS',
              icon: LucideIcons.building2,
              onPressed: _openVillas,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse 3 African heritage villas and their cultural treasures',
            style: AfrilensTheme.bodyText.copyWith(fontSize: 12, color: AfrilensColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GoldButton(
              text: 'SCAN ARTIFACT',
              icon: LucideIcons.scan,
              onPressed: _switchToScanTab,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Point your camera at any artifact to hear its centuries-old story',
            style: AfrilensTheme.bodyText.copyWith(fontSize: 12, color: AfrilensColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 20),
          child: Text(
            'Featured Artifacts',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AfrilensColors.textPrimary,
            ),
          ),
        ),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AfrilensColors.gold, strokeWidth: 2),
            ),
          )
        else if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Icon(LucideIcons.wifiOff, color: AfrilensColors.textMuted, size: 36),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: AfrilensTheme.bodyText.copyWith(color: AfrilensColors.textMuted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _loadData,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AfrilensColors.gold, width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Retry', style: AfrilensTheme.goldAccent.copyWith(fontSize: 13)),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _featured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final artifact = _featured[index];
                return SizedBox(
                  width: 220,
                  child: ArtifactCard(
                    artifact: artifact,
                    height: 280,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ArtifactDetailScreen(artifact: artifact)),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  IconData get _icon {
    if (notification.id.startsWith('order_')) return LucideIcons.checkCircle;
    if (notification.id == 'welcome') return LucideIcons.sparkles;
    return LucideIcons.compass;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: notification.isRead
                  ? AfrilensColors.surfaceLight
                  : AfrilensColors.gold.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _icon,
              size: 18,
              color: notification.isRead ? AfrilensColors.textMuted : AfrilensColors.gold,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
                          color: AfrilensColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AfrilensColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: AfrilensTheme.bodyText.copyWith(fontSize: 13, color: AfrilensColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeAgo(notification.timestamp),
                  style: GoogleFonts.inter(fontSize: 11, color: AfrilensColors.textMuted.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
