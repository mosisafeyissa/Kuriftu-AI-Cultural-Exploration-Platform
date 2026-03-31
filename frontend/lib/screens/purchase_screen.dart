import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/api_service.dart';
import '../models/order.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  List<Order>? _orders;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final orders = await ApiService.getOrders();
      if (mounted) setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not fetch orders'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KuriftuColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (_isLoading)
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
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Purchases',
                style: TextStyle(fontFamily: 'PlayfairDisplay', 
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: KuriftuColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.logIn, color: KuriftuColors.gold),
                tooltip: 'Switch User',
                onPressed: _showLoginDialog,
              )
            ],
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
            style: TextStyle(fontFamily: 'PlayfairDisplay', 
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

  void _showLoginDialog() {
    final controller = TextEditingController(text: ApiService.currentEmail);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: KuriftuColors.surface,
          title: Text('Switch User', style: KuriftuTheme.bodyText.copyWith(color: KuriftuColors.gold, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: KuriftuColors.gold)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: KuriftuColors.gold)),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                final email = controller.text.trim();
                if (email.isNotEmpty) {
                  ApiService.currentEmail = email;
                  Navigator.pop(context);
                  _fetchOrders();
                }
              },
              child: const Text('Log In', style: TextStyle(color: KuriftuColors.gold)),
            ),
          ],
        );
      },
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
                    'Order #${order.id.length > 6 ? order.id.substring(order.id.length - 6) : order.id}',
                    style: TextStyle(fontFamily: 'Inter', 
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
                style: TextStyle(fontFamily: 'Inter', 
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

