// Renders the tappable delivery-address label used in the Home app bar.
import 'package:flutter/material.dart';

/// Displays a formatted address and delegates editing to its parent.
class HomeDeliveryAddress extends StatelessWidget {
  /// Receives the current address label and the callback that opens editing.
  const HomeDeliveryAddress({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;

  /// Builds the existing one-line address control for the Home app bar.
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Row(
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 19),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
      ],
    ),
  );
}
