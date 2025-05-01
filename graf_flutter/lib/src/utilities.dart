import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

// Assumes [position] is relative to a box of [size] where `0,0` is in the
// middle.
Offset wallForce({
  required Offset position,
  required Size size,
  required double buffer,
  required double maxForce,
}) {
  final value = Offset(
    wallForceImpl(position.dx, size.width, buffer, maxForce),
    wallForceImpl(position.dy, size.height, buffer, maxForce),
  );

  assert(value.dx <= maxForce);
  assert(value.dy <= maxForce);

  return limitMagnitude(value, maxForce);
}

Offset limitMagnitude(Offset velocity, double maxMagnitude) {
  final distance = velocity.distance;
  if (distance > maxMagnitude) {
    velocity *= maxMagnitude / velocity.distance;
  }
  return velocity;
}

@visibleForTesting
double wallForceImpl(
  double position,
  double size,
  double buffer,
  double maxForce,
) {
  assert(position.isFinite);
  assert(size.isFinite);
  assert(size > 0);
  assert(buffer > 0);
  assert(size >= 2 * buffer);
  assert(maxForce >= 0);

  final leftWall = -size / 2;
  final rightWall = size / 2;

  final leftBuffer = leftWall + buffer;
  final rightBuffer = rightWall - buffer;

  assert(leftBuffer <= rightBuffer);

  if (position < leftWall) {
    return maxForce;
  }
  if (position < leftBuffer) {
    return maxForce * (leftBuffer - position) / buffer;
  }
  if (position > rightWall) {
    return -maxForce;
  }
  if (position > rightBuffer) {
    return -maxForce * (position - rightBuffer) / buffer;
  }

  return 0;
}
