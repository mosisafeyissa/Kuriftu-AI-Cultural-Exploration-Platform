import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GoldButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final double height;
  final IconData? icon;

  const GoldButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.height = 56,
    this.icon,
  });

  static const _gradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AfrilensColors.gold,
            side: const BorderSide(color: AfrilensColors.gold, width: 1.5),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 32),
          ),
          child: _buildChild(AfrilensColors.gold),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed != null && !isLoading ? _gradient : null,
        color: onPressed == null || isLoading
            ? AfrilensColors.goldDark.withOpacity(0.4)
            : null,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: onPressed != null && !isLoading
            ? const [BoxShadow(color: Color(0x40D4AF37), blurRadius: 12, offset: Offset(0, 4))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(height / 2),
          child: Center(child: _buildChild(Colors.black)),
        ),
      ),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: color,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: color,
      ),
    );
  }
}
