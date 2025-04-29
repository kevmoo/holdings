// edge_painter.dart (Reusing from previous example)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graf/graf.dart';

class EdgePainter<T> extends CustomPainter {
  final GraphData<T> _graphData;
  final Map<T, Offset> _nodePositions;

  EdgePainter(this._graphData, this._nodePositions);

  final _edgePaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.6)
    ..strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);

    if (kDebugMode) {
      final bounds = _nodePositions.values.fold<Rect>(_infiniteRect, (
        bounds,
        pos,
      ) {
        final posRect = pos & Size.zero;
        if (bounds.isInfinite) {
          return posRect;
        }
        return bounds.expandToInclude(posRect);
      });
      canvas.drawRect(bounds, Paint()..color = Colors.blue.withAlpha(20));
    }

    for (var edge in _graphData.edges) {
      final startPos = _nodePositions[edge.from];
      final endPos = _nodePositions[edge.to];

      if (startPos != null && endPos != null) {
        canvas.drawLine(startPos, endPos, _edgePaint);
      }
    }

    canvas.drawCircle(Offset.zero, 10, _edgePaint);
  }

  @override
  bool shouldRepaint(covariant EdgePainter<T> oldDelegate) =>
      // the values within _graphData and/or _nodePositions may have changed
      // so we're just going with true for now
      true;
}

const _infiniteRect = Rect.fromLTRB(
  double.infinity,
  double.infinity,
  double.infinity,
  double.infinity,
);
