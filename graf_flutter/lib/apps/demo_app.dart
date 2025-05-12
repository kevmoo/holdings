import 'package:flutter/material.dart';

import '../src/graph_widget.dart';
import 'app_utils.dart';
import 'demo_graph.dart';

int _initialCount() {
  var targetCount = 100;

  try {
    final targetString = Uri.base.queryParameters['target'];
    if (targetString != null) {
      targetCount = int.tryParse(targetString) ?? targetCount;
    }
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    print('some error getting frames, sticking with $targetCount');
  }

  return targetCount;
}

final _data = DemoGraph(targetCount: _initialCount());

final DemoStuff demoStuff = (
  factory: nodeDemoFactory,
  timerCallback: (double fps, bool isSlow) {
    if (fps < 55 && _data.size > 20) {
      _data.removeNode();
      if (!isSlow) {
        _data.removeNode();
        _data.removeNode();
        _data.removeNode();
        _data.removeNode();
      }
    } else if (fps > 59 && _data.size < 2000) {
      _data.addNode();
      if (!isSlow) {
        _data.addNode();
        _data.addNode();
        _data.addNode();
        _data.addNode();
      }
    }
  },
);

Widget nodeDemoFactory() => ForceDirectedGraphView<int>(
  centerForce: 0,
  damping: 0.0001,
  graphData: _data,
  nodeSize: 40,
  nodeWidgetFactory: _createNode,
  repulsionConstant: 1000,
  springStiffness: 0,
);

Widget _createNode(_) => const DecoratedBox(
  child: Padding(padding: EdgeInsets.all(5), child: FlutterLogo(size: 30)),
  decoration: _circleShadowDecoration,
);

const _circleShadowDecoration = BoxDecoration(
  color: Colors.white,
  shape: BoxShape.circle,
  border: Border.fromBorderSide(
    BorderSide(
      color: Color(0xFF1565C0), // Material.blue 800
      width: 1.5,
    ),
  ),
  boxShadow: [
    BoxShadow(
      color: Color(0x440000000), // Colors.black.withValues(alpha: 0.2),
      blurRadius: 1,
      offset: Offset(1, 1),
    ),
  ],
);
