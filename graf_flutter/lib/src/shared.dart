import 'package:flutter/material.dart';

final circleShadowDecoration = BoxDecoration(
  color: Colors.blue.shade100,
  shape: BoxShape.circle,
  border: Border.all(color: Colors.blue.shade800, width: 1.5),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 3,
      offset: const Offset(1, 1),
    ),
  ],
);
