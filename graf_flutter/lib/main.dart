import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'graf_flutter.dart';
import 'src/demo_graph.dart';

void main() {
  runApp(const MyApp());

  Timer.periodic(const Duration(milliseconds: 500), _onTimer);
}

void _onTimer(Timer bob) {
  if (_fps < 55 && _data.targetCount > 10) {
    _data.targetCount--;
  } else if (_fps > 58 && _data.targetCount < 1000) {
    _data.targetCount++;
  }

  _data.churn();
}

final _data = DemoGraph(targetCount: 400);

// TODO: this is BAD. Global state bad!
double _fps = 0;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(scaffoldBackgroundColor: Colors.white),
    home: Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ForceDirectedGraphView<int>(graphData: _data, nodeSize: 40),
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
              const _FrameSilly(),
            ],
          ),
        ],
      ),
    ),
  );
}

class _FrameSilly extends StatefulWidget {
  const _FrameSilly();

  @override
  State<_FrameSilly> createState() => _FrameSillyState();
}

class _FrameSillyState extends State<_FrameSilly>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  final _frameTimes = List<int>.generate(60 * 5, (i) => -1, growable: false);
  Duration _lastTick = Duration.zero;
  int _frameSum = 0;
  int _index = 0;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastTick;
    _lastTick = elapsed;
    if (delta.inSeconds > 0) {
      print('long frame!');
      return;
    }

    final lastValue = _frameTimes[_index];

    if (lastValue.isNegative) {
      // we are filling things up!
      _count = _index + 1;
      // No need to decrement _frameSum
    } else {
      _count = _frameTimes.length;
      _frameSum -= lastValue;
      // we are already full!
    }
    _frameTimes[_index] = delta.inMicroseconds;
    _frameSum += delta.inMicroseconds;

    _index = (_index + 1) % _frameTimes.length;

    setState(() {
      _fps = Duration.microsecondsPerSecond / (_frameSum / _count);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 100,
    child: Text(
      'Size: ${_data.size} '
      'Target: ${_data.targetCount} '
      'FPS: ${_fps.toStringAsFixed(2)}',
      style: const TextStyle(fontFamily: 'monospace'),
      textAlign: TextAlign.start,
    ),
  );
}
