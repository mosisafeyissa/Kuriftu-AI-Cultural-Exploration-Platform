import 'package:flutter/material.dart';
import 'scan_screen.dart';
import 'villas_screen.dart';

// Assuming we have simple detail routes or coming soons for Stories/Orders
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildHomeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F5EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 32, color: const Color(0xFFC79A3F)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Kuriftu Village',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFF2C3E50)),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discover',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 32),
            _buildHomeCard(
              context: context,
              title: 'Scan Cultural Object',
              subtitle: 'AI-powered artifact discovery',
              icon: Icons.center_focus_weak,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildHomeCard(
              context: context,
              title: 'Explore African Villas',
              subtitle: 'Find items by origin',
              icon: Icons.account_balance,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VillasScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildHomeCard(
              context: context,
              title: 'Discover Cultural Stories',
              subtitle: 'Read the legends behind the craft',
              icon: Icons.menu_book,
              onTap: () {
                // Future expansion
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stories coming soon!')),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildHomeCard(
              context: context,
              title: 'My Orders',
              subtitle: 'Manage your purchased heritage',
              icon: Icons.shopping_bag_outlined,
              onTap: () {
                // Future expansion
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Orders view coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
