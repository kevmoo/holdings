import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../src/frame_silly.dart' as silly;
import '../src/graph_widget.dart';
import '../src/simple_notifier.dart';
import 'app_utils.dart';
import 'demo_graph.dart';

final _timings = ListQueue<FrameTiming>();

final _notifier = SimpleNotifier();

void main() {
  runApp(const DemoApp());

  SchedulerBinding.instance.addTimingsCallback(_onTimings);

  Timer.periodic(const Duration(milliseconds: 200), _onTimer);
}

void _onTimings(List<FrameTiming> timings) {
  _timings.addAll(timings);
}

final _isMaxMode = Uri.base.queryParameters.containsKey('max');

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

void _onTimer(Timer bob) {
  if (_timings.isNotEmpty) {
    while (_timings.length > 200) {
      _timings.removeFirst();
    }
    final stats = allTheStats(_timings);

    silly.buildTime = stats.buildDuration;
    silly.rasterTime = stats.rasterDuration;
    silly.totalSpan = stats.totalSpan;
  }

  final magicNumber = _isMaxMode
      ? max(silly.rasterTime, silly.buildTime)
      : silly.totalSpan;

  silly.fps = 1 / (magicNumber / 1000);

  if (silly.fps < 55 && _data.size > 20) {
    _data.removeNode();
    _data.removeNode();
    _data.removeNode();
    _data.removeNode();
    _data.removeNode();
  } else if (silly.fps < 60 && _data.targetCount > 10) {
    _data.removeNode();
  } else if (silly.fps > 70 && _data.targetCount < 2000) {
    _data.addNode();
    _data.addNode();
    _data.addNode();
    _data.addNode();
    _data.addNode();
  } else if (silly.fps > 65 && _data.targetCount < 2000) {
    _data.addNode();
  }

  _notifier.notify();
}

final _data = DemoGraph(targetCount: _initialCount());

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
              centerForce: 0,
              damping: 0.0001,
              graphData: _data,
              nodeSize: 40,
              nodeWidgetFactory: _createNode,
              repulsionConstant: 1000,
              springStiffness: 0,
            ),
          ),
          ListenableBuilder(
            listenable: _notifier,
            builder: (ctx, child) => Text(_text()),
          ),
        ],
      ),
    ),
  );
}

String _text() =>
    '''
Widget count: ${_data.size}       FPS: ${silly.fps.toStringAsFixed(1)}   Max mode: $_isMaxMode
Times (ms): build ${silly.buildTime.toStringAsFixed(1)}   raster  ${silly.rasterTime.toStringAsFixed(1)}    total ${silly.totalSpan.toStringAsFixed(1)}''';

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
