import 'dart:async';

import 'package:flutter/material.dart';

import '../src/frame_silly.dart' as silly;
import '../src/graph_widget.dart';
import 'demo_graph.dart';

void main() {
  runApp(const DemoApp());

  Timer.periodic(const Duration(milliseconds: 500), _onTimer);
}

void _onTimer(Timer bob) {
  if (silly.fps < 55 && _data.targetCount > 10) {
    _data.targetCount--;
  } else if (silly.fps > 58 && _data.targetCount < 1000) {
    _data.targetCount++;
  }

  _data.churn();

  silly.actualGraphSize = _data.size;
  silly.targetGraphSize = _data.targetCount;
}

final _data = DemoGraph(targetCount: 400);

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(scaffoldBackgroundColor: Colors.white),
    home: Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ForceDirectedGraphView<int>(
              graphData: _data,
              nodeSize: 40,
              springStiffness: 0,
              repulsionConstant: 0,
              damping: 0,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: _data.churn,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(onPressed: _data.addNode, icon: const Icon(Icons.add)),
              IconButton(
                onPressed: _data.removeNode,
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                onPressed: _data.addEdge,
                icon: const Icon(Icons.link),
              ),
              IconButton(
                onPressed: _data.removeEdge,
                icon: const Icon(Icons.link_off),
              ),
              const silly.FrameSilly(),
            ],
          ),
        ],
      ),
    ),
  );
}
