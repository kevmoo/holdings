// ignore_for_file: prefer_const_constructors

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graf_flutter/src/utilities.dart'; // Adjust import path if needed

void main() {
  const buffer = 10.0;
  const maxForce = 2.0;
  const size = Size(100, 100);
  final testData =
      <({String description, Offset location, Object expectedForce})>[
        (
          description: 'center',
          location: Offset.zero,
          expectedForce: Offset.zero,
        ),
        (
          description: 'left',
          location: Offset(size.width / -2, 0),
          expectedForce: Offset(maxForce, 0),
        ),
        (
          description: 'too left',
          location: Offset(size.width / -2 - buffer, 0),
          expectedForce: Offset(maxForce, 0),
        ),
        (
          description: 'a bit left',
          location: Offset(size.width / -2 + buffer / 2, 0),
          expectedForce: Offset(maxForce / 2, 0),
        ),
        (
          description: 'right',
          location: Offset(size.width / 2, 0),
          expectedForce: Offset(-maxForce, 0),
        ),
        (
          description: 'too right',
          location: Offset(size.width / 2 + buffer, 0),
          expectedForce: Offset(-maxForce, 0),
        ),
        (
          description: 'a bit right',
          location: Offset(size.width / 2 - buffer / 2, 0),
          expectedForce: Offset(-maxForce / 2, 0),
        ),
        (
          description: 'top',
          location: Offset(0, -size.height / 2),
          expectedForce: Offset(0, maxForce),
        ),
        (
          description: 'bottom',
          location: Offset(0, size.height / 2),
          expectedForce: Offset(0, -maxForce),
        ),
        (
          description: 'too far upper left',
          location: Offset(-size.width, -size.height),
          expectedForce: isA<Offset>().having(
            (e) => e.distance,
            'distance',
            closeTo(maxForce, 0.001),
          ),
        ),
      ];

  for (var testDatum in testData) {
    test(testDatum.description, () {
      expect(
        wallForce(
          position: testDatum.location,
          size: size,
          buffer: buffer,
          maxForce: maxForce,
        ),
        testDatum.expectedForce,
      );
    });
  }
}
