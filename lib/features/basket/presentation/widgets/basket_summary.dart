import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grabber_app/core/constants/app_colors.dart';

/// Shows the basket count and subtotal and opens the full basket on tap.
class BasketSummary extends StatelessWidget {
  /// Receives computed basket values and the navigation callback.
  const BasketSummary({
    super.key,
    required this.totalItemQuantity,
    required this.subtotalCents,
    required this.onOpenBasket,
  });

  final int totalItemQuantity;
  final int? subtotalCents;
  final VoidCallback onOpenBasket;

  /// Formats an integer-cent amount for display with two decimal places.
  String _formatCents(int cents) {
    final wholeUnits = cents ~/ 100;
    final fractionalUnits = (cents % 100).toString().padLeft(2, '0');
    return '$wholeUnits.$fractionalUnits';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
      child: Material(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onOpenBasket,
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Badge(
                    backgroundColor: Colors.red,
                    label: Text(
                      totalItemQuantity.toString(),
                      style: const TextStyle(fontSize: 13),
                    ),
                    largeSize: 13,
                    child: SvgPicture.asset(
                      'assets/icons/basket.svg',
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      subtotalCents == null
                          ? 'Subtotal unavailable'
                          : 'Subtotal: \$ ${_formatCents(subtotalCents!)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Text(
                    'View Basket',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
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
}
