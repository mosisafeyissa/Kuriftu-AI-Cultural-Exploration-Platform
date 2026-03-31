import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/artifact.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import '../widgets/glass_card.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/notification_provider.dart';

class OrderScreen extends StatefulWidget {
  final Artifact artifact;

  const OrderScreen({super.key, required this.artifact});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int _quantity = 1;
  final _emailController = TextEditingController();
  bool _isPlacing = false;

  double get _total => widget.artifact.price * _quantity;

  Future<void> _placeOrder() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Please enter a valid email address');
      return;
    }

    setState(() => _isPlacing = true);

    try {
      final order = await ApiService.createOrder(
        artifactId: widget.artifact.id,
        email: email,
        quantity: _quantity,
      );
      if (mounted) {
        ApiService.currentEmail = email;  // Save newly entered email
        context.read<NotificationProvider>().addOrderNotification(order.id, widget.artifact.name);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) _showSnack('Order failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: KuriftuColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: KuriftuColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: KuriftuColors.glassBorder, width: 0.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: KuriftuColors.gold.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.checkCircle,
                      color: KuriftuColors.gold,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Order Confirmed',
                    style: TextStyle(fontFamily: 'PlayfairDisplay', 
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: KuriftuColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total: \$${_total.toStringAsFixed(2)}\nReceipt sent to ${_emailController.text}',
                    textAlign: TextAlign.center,
                    style: KuriftuTheme.bodyText.copyWith(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: GoldButton(
                      text: 'DONE',
                      onPressed: () {
                        Navigator.pop(context); // dialog
                        Navigator.pop(context); // order
                        Navigator.pop(context); // detail/result
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KuriftuColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
          ),
        ),
        title: Text(
          'Checkout',
          style: TextStyle(fontFamily: 'PlayfairDisplay', 
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: KuriftuColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item summary card
            GlassCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: widget.artifact.image.startsWith('assets/')
                        ? Image.asset(widget.artifact.image,
                            width: 80, height: 80, fit: BoxFit.cover)
                        : Image.network(widget.artifact.image,
                            width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.artifact.name,
                          style: KuriftuTheme.headlineSerif.copyWith(fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.artifact.countryName,
                          style: KuriftuTheme.goldAccent.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${widget.artifact.price.toStringAsFixed(2)}',
                          style: TextStyle(fontFamily: 'PlayfairDisplay', 
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: KuriftuColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quantity
            Text(
              'QUANTITY',
              style: KuriftuTheme.labelText.copyWith(letterSpacing: 2),
            ),
            const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(LucideIcons.minus),
                    color: KuriftuColors.gold,
                    disabledColor: KuriftuColors.textMuted,
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '$_quantity',
                    style: TextStyle(fontFamily: 'PlayfairDisplay', 
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: KuriftuColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(LucideIcons.plus),
                    color: KuriftuColors.gold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Email
            Text(
              'YOUR EMAIL',
              style: KuriftuTheme.labelText.copyWith(letterSpacing: 2),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: KuriftuTheme.bodyText.copyWith(
                    color: KuriftuColors.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'guest@kuriftu.com',
                    hintStyle: KuriftuTheme.bodyText.copyWith(
                      color: KuriftuColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.mail,
                      color: KuriftuColors.textMuted,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 0.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: KuriftuColors.gold,
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Total
            GlassCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: KuriftuTheme.bodyText.copyWith(
                      fontSize: 18,
                      color: KuriftuColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${_total.toStringAsFixed(2)}',
                    style: TextStyle(fontFamily: 'PlayfairDisplay', 
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: KuriftuColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: GoldButton(
                text: 'CONFIRM ORDER',
                icon: LucideIcons.checkCircle,
                isLoading: _isPlacing,
                onPressed: _placeOrder,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

