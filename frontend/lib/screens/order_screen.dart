import 'package:flutter/material.dart';
import '../models/artifact.dart';
import '../widgets/primary_button.dart';

class OrderScreen extends StatefulWidget {
  final Artifact artifact;

  const OrderScreen({super.key, required this.artifact});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int _quantity = 1;
  final TextEditingController _emailController = TextEditingController();
  bool _isPlacingOrder = false;

  void _confirmOrder() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() { _isPlacingOrder = true; });
    
    // Simulate API request delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() { _isPlacingOrder = false; });
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Order Confirmed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Your total is \$${(widget.artifact.price * _quantity).toStringAsFixed(2)}. A receipt will be sent to ${_emailController.text}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Pop dialog
                Navigator.pop(context);
                // Pop Order Screen
                Navigator.pop(context);
                // Pop Detail/Result
                Navigator.pop(context);
              },
              child: const Text('BACK TO HOME', style: TextStyle(color: Color(0xFFC79A3F), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Color(0xFF2C3E50))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      widget.artifact.image,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.artifact.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${widget.artifact.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC79A3F),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Quantity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (_quantity > 1) {
                      setState(() { _quantity--; });
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFFC79A3F),
                  iconSize: 32,
                ),
                Text('$_quantity', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                IconButton(
                  onPressed: () {
                    setState(() { _quantity++; });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFFC79A3F),
                  iconSize: 32,
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Your Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'guest@kuriftu.com',
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Cost:', style: TextStyle(fontSize: 20, color: Colors.grey)),
                  Text(
                    '\$${(widget.artifact.price * _quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: 'CONFIRM ORDER',
                isLoading: _isPlacingOrder,
                onPressed: _confirmOrder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
