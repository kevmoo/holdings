import 'dart:async';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../src/frame_silly.dart' as silly;
import '../src/graph_widget.dart';
import 'demo_graph.dart';

void main() {
  runApp(const DemoApp());

  Timer.periodic(const Duration(milliseconds: 500), _onTimer);
}

int _frames() {
  var frames = 500;

  try {
    final uri = Uri.parse(web.window.location.href);
    final framesString = uri.queryParameters['target'];
    if (framesString != null) {
      frames = int.parse(framesString);
    }
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    print('some error getting frames, sticking with $frames');
  }

  print('frames! $frames');
  return frames;
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

final _data = DemoGraph(targetCount: _frames());

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
              nodeWidgetFactory: _createNode,
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
