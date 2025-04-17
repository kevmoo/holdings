// Define a FlowDelegate to position the nodes
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/widgets.dart';

class NodeFlowDelegate<T> extends FlowDelegate {
  final Iterable<Offset> _nodePositions;
  final double nodeSize;

  NodeFlowDelegate({
    required Iterable<Offset> nodePositions,
    required this.nodeSize,
    required Listenable repaint,
  }) : _nodePositions = nodePositions,
       super(repaint: repaint);

  @override
  void paintChildren(FlowPaintingContext context) {
    final centerOffset = context.size.center(Offset.zero);

    var i = 0;
    for (var position in _nodePositions) {
      // Flow paints children from their top-left corner.
      // Convert center position from simulation to top-left.
      final topLeft =
          centerOffset + position - Offset(nodeSize / 2, nodeSize / 2);

      // Paint the child (NodeWidget) at the calculated position
      context.paintChild(
        i, // The index of the child in the Flow's children list
        transform: Matrix4.translationValues(topLeft.dx, topLeft.dy, 0.0),
      );

      i++;
    }
  }

  @override
  bool shouldRepaint(covariant NodeFlowDelegate oldDelegate) =>
      // Repaint if node positions, size, or the nodes themselves change.
      // A deep comparison of nodePositions might be needed for accuracy,
      // but comparing identity might suffice if the map instance changes.
      // For simplicity here, we'll compare references and nodeSize.
      // The Listenable approach in the constructor handles position changes.
      oldDelegate._nodePositions != _nodePositions ||
      oldDelegate.nodeSize != nodeSize; // Reference check for nodes list
}
