// edge_painter.dart (Reusing from previous example)
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:graf/graf.dart';

import 'node_data.dart';

class EdgePainter<T> extends CustomPainter {
  final GraphData<T> _graphData;
  final Map<T, NodeData> _nodePositions;

  EdgePainter(this._graphData, this._nodePositions, {required super.repaint});

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
        canvas.drawPath(_arrowPath(startPos, endPos), _edgePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant EdgePainter<T> oldDelegate) =>
      // the values within _graphData and/or _nodePositions may have changed
      // so we're just going with true for now
      true;
}

const _arrowAngle = math.pi / 6;
const _arrowSize = 10;

Path _arrowPath(Offset start, Offset end) {
  // Calculate the midpoint of the line, this will be the tip of the arrow
  final p0 = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

  // Calculate the angle of the line
  final dx = end.dx - start.dx;
  final dy = end.dy - start.dy;
  final angle = math.atan2(dy, dx);

  // Calculate the coordinates for the two base points of the triangle,
  // relative to the midpoint (p0)
  final p1 = Offset(
    p0.dx - _arrowSize * math.cos(angle - _arrowAngle),
    p0.dy - _arrowSize * math.sin(angle - _arrowAngle),
  );
  final p2 = Offset(
    p0.dx - _arrowSize * math.cos(angle + _arrowAngle),
    p0.dy - _arrowSize * math.sin(angle + _arrowAngle),
  );

  // Path for the arrowhead
  final arrowPath = Path()
    ..moveTo(p0.dx, p0.dy) // Tip at midpoint
    ..lineTo(p1.dx, p1.dy) // Base point 1
    ..lineTo(p2.dx, p2.dy) // Base point 2
    ..close(); // Connects the last point to the first

  return arrowPath;
}
