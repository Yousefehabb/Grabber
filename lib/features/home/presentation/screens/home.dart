// Presents the shopping landing page and the current delivery-address label.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grabber_app/features/home/data/home_categories_data.dart';
import 'package:grabber_app/features/home/presentation/widgets/home_delivery_address.dart';
import 'package:grabber_app/features/home/presentation/widgets/home_categories_section.dart';
import 'package:grabber_app/features/home/presentation/widgets/home_promotions.dart';

class Home extends StatefulWidget {
  /// Receives navigation callbacks and the address label for the active user.
  const Home({
    super.key,
    required this.onOpenBasket,
    this.deliveryAddressLabel = 'Delivery address unavailable',
    this.onEditAddress,
  });

  final VoidCallback onOpenBasket;
  final String deliveryAddressLabel;
  final VoidCallback? onEditAddress;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: SizedBox.shrink(),
        leadingWidth: 0,
        title: Row(
          children: [
            SvgPicture.asset("assets/icons/motor.svg"),
            const SizedBox(width: 10),
            Expanded(
              child: HomeDeliveryAddress(
                label: widget.deliveryAddressLabel,
                onTap: widget.onEditAddress,
              ),
            ),
            Spacer(),
            IconButton(
              tooltip: 'Open basket',
              onPressed: widget.onOpenBasket,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              icon: SvgPicture.asset("assets/icons/basket.svg"),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            /// banner
            HomePromotions(),

            /// category
            HomeCategoriesSection(categories: homeCategories),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/banners/grabber_home_ad.png',
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
