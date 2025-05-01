import 'package:flutter/material.dart';

const _doText = false;

class NodeWidget<T> extends StatelessWidget {
  final T node;
  final double size;

  const NodeWidget({super.key, required this.node, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
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
    ),
    child: Center(
      child: _doText
          ? Text(
              node.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size * 0.2, // Adjust font size relative to node size
              ),
              overflow: TextOverflow.ellipsis, // Prevent text overflow
            )
          : const Icon(Icons.flag),
    ),
  );
}
