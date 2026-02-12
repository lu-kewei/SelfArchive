import 'package:flutter/material.dart';

class DetectiveWallBackground extends StatelessWidget {
  final String asset;

  const DetectiveWallBackground(this.asset, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.asset(
        asset,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
