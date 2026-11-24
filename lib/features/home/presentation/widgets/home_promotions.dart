// Builds the rotating promotional banner carousel for Home.
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

/// Displays the Home screen's advertising banners.
class HomePromotions extends StatelessWidget {
  const HomePromotions({super.key});

  static const _bannerImages = [
    "assets/banners/Slider 1.png",
    "assets/banners/Slider 2.png",
    "assets/banners/Slider 3.png",
  ];

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: _bannerImages.length,
      itemBuilder:
          (BuildContext context, int itemIndex, int pageViewIndex) =>
              Image.asset(_bannerImages[itemIndex]),
      options: CarouselOptions(
        height: 170,
        aspectRatio: 1,
        viewportFraction: 0.6,
        autoPlay: true,
        autoPlayInterval: Duration(seconds: 3),
        autoPlayAnimationDuration: Duration(seconds: 3),
        autoPlayCurve: Curves.linear,
        enlargeCenterPage: true,
      ),
    );
  }
}
