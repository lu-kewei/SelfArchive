import 'package:flutter/material.dart';

class CameraState {
  final Matrix4 transform;

  const CameraState(this.transform);

  double get scale => transform.getMaxScaleOnAxis();

  // Translation (pan)
  double get dx => transform.getTranslation().x;
  double get dy => transform.getTranslation().y;

  Offset get pan => Offset(dx, dy);

  factory CameraState.initial() {
    return CameraState(Matrix4.identity());
  }

  Offset screenToWorld(Offset screenPoint) {
    // Apply inverse matrix
    final inverse = Matrix4.tryInvert(transform) ?? Matrix4.identity();
    return MatrixUtils.transformPoint(inverse, screenPoint);
  }

  Offset worldToScreen(Offset worldPoint) {
    return MatrixUtils.transformPoint(transform, worldPoint);
  }

  @override
  String toString() =>
      'CameraState(scale: ${scale.toStringAsFixed(2)}, pan: $pan)';
}
