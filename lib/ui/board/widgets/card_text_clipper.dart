import 'package:flutter/material.dart';
import '../../../scene/models/node_entity.dart';

class CardTextClipper extends CustomClipper<Path> {
  final NodeEntity node;
  final String? assetImage;

  CardTextClipper({required this.node, this.assetImage});

  @override
  Path getClip(Size size) {
    if (node.shape == CardShape.circle || 
        (assetImage != null && assetImage!.contains('hanging_tag'))) {
      final path = Path();
      path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }
    
    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    return path;
  }

  @override
  bool shouldReclip(covariant CardTextClipper oldClipper) {
    return oldClipper.node.shape != node.shape ||
           oldClipper.assetImage != assetImage;
  }
}
