import 'package:flutter/material.dart';

import 'shared.dart';

class DefaultNodeWidget<T> extends StatelessWidget {
  final T node;
  final double size;

  const DefaultNodeWidget({super.key, required this.node, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: circleShadowDecoration,
    child: Center(
      child: Text(
        node.toString(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size * 0.2, // Adjust font size relative to node size
        ),
        overflow: TextOverflow.ellipsis, // Prevent text overflow
      ),
    ),
  );
}
