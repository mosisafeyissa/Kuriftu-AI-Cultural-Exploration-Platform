import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import '../widgets/glass_card.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  List<Order>? _orders;
  bool _isLoading = false;
  String? _error;
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        _loadOrders();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated && !_wasAuthenticated) {
      _loadOrders();
    }
    _wasAuthenticated = auth.isAuthenticated;
  }

  Future<void> _loadOrders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final orders = await ApiService.getMyOrders();
      if (mounted) setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not fetch orders'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          backgroundColor: KuriftuColors.background,
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                if (!auth.isAuthenticated)
                  SliverToBoxAdapter(child: _buildLoginPrompt())
                else if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: KuriftuColors.gold, strokeWidth: 2)),
                  )
                else if (_error != null)
                  SliverToBoxAdapter(child: _buildError())
                else if (_orders != null && _orders!.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else if (_orders != null)
                  _buildOrderList(),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Purchases',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: KuriftuColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your cultural collection',
            style: KuriftuTheme.bodyText.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KuriftuColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.logIn, size: 36, color: KuriftuColors.gold),
            ),
            const SizedBox(height: 24),
            Text(
              'Sign In to View Orders',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: KuriftuColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Log in to see your purchase history\nand track your cultural collection.',
              textAlign: TextAlign.center,
              style: KuriftuTheme.bodyText.copyWith(height: 1.7),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: GoldButton(
                text: 'SIGN IN',
                icon: LucideIcons.logIn,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: KuriftuColors.gold.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.package, size: 40, color: KuriftuColors.gold),
          ),
          const SizedBox(height: 24),
          Text(
            'No Orders Yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: KuriftuColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Scan an artifact to begin collecting\npieces of living African heritage.',
            textAlign: TextAlign.center,
            style: KuriftuTheme.bodyText.copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        children: [
          const Icon(LucideIcons.alertCircle, size: 40, color: Color(0xFFFF6B6B)),
          const SizedBox(height: 16),
          Text(_error!, style: KuriftuTheme.bodyText.copyWith(color: const Color(0xFFFF6B6B))),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _loadOrders,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: KuriftuColors.gold, width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Retry', style: KuriftuTheme.goldAccent.copyWith(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  SliverList _buildOrderList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final order = _orders![index];
          return _OrderCard(order: order);
        },
        childCount: _orders!.length,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return const Color(0xFF4CAF50);
      case 'processing': return const Color(0xFF2196F3);
      case 'cancelled': return const Color(0xFFFF6B6B);
      default: return KuriftuColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: KuriftuColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.box, color: KuriftuColors.gold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.artifactName.isNotEmpty
                        ? order.artifactName
                        : 'Order #${order.id.length > 6 ? order.id.substring(order.id.length - 6) : order.id}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: KuriftuColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qty: ${order.quantity}${order.createdAt != null ? '  •  ${_formatDate(order.createdAt!)}' : ''}',
                    style: KuriftuTheme.bodyText.copyWith(fontSize: 12),
                  ),
                  if (order.totalAmount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '\$${order.totalAmount.toStringAsFixed(2)}',
                        style: KuriftuTheme.goldAccent.copyWith(fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(order.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                order.status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(order.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
