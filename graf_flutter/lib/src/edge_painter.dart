// edge_painter.dart (Reusing from previous example)
import 'package:flutter/material.dart';
import 'package:graf/graf.dart';

import 'node_data.dart';

class EdgePainter<T> extends CustomPainter {
  final GraphData<T> _graphData;
  final Map<T, NodeData> _nodePositions;

  EdgePainter(this._graphData, this._nodePositions);

  final _edgePaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.6)
    ..strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);

    for (var edge in _graphData.edges) {
      final startPos = _nodePositions[edge.from]?.position;
      final endPos = _nodePositions[edge.to]?.position;

      if (startPos != null && endPos != null) {
        canvas.drawLine(startPos, endPos, _edgePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant EdgePainter<T> oldDelegate) =>
      // the values within _graphData and/or _nodePositions may have changed
      // so we're just going with true for now
      true;
}
