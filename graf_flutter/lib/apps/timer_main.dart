import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../src/frame_silly.dart' as silly;
import '../src/simple_notifier.dart';
import 'app_utils.dart';
import 'demo_graph.dart';

final _timings = ListQueue<FrameTiming>();

final _notifier = SimpleNotifier();

void startApp({required DemoStuff demoStuff}) {
  runApp(TimerApp(factory: demoStuff.factory));

  SchedulerBinding.instance.addTimingsCallback(_onTimings);

  void onTimer(Timer bob) {
    if (_timings.isNotEmpty) {
      while (_timings.length > 200) {
        _timings.removeFirst();
      }
      final mostRecentRasterFinish = _timings.last.timestampInMicroseconds(
        FramePhase.rasterFinish,
      );
      final oneSecondAgo =
          mostRecentRasterFinish - const Duration(seconds: 1).inMicroseconds;
      double frameCount = 0;
      for (final timing in _timings) {
        if (timing.timestampInMicroseconds(FramePhase.rasterFinish) >
            oneSecondAgo) {
          frameCount++;
        }
      }
      silly.fps = frameCount;
      final stats = allTheStats(_timings);

      silly.buildTime = stats.buildDuration;
      silly.rasterTime = stats.rasterDuration;
      silly.totalSpan = stats.totalSpan;
    }

    demoStuff.timerCallback(silly.fps, _isSlow);

    _notifier.notify();
  }

  Timer.periodic(Duration(milliseconds: _isSlow ? 500 : 200), onTimer);
}

void _onTimings(List<FrameTiming> timings) {
  _timings.addAll(timings);
}

final _isSlow = Uri.base.queryParameters.containsKey('slow');

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

class TimerApp extends StatelessWidget {
  const TimerApp({required this.factory, super.key});

  final Widget Function() factory;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(scaffoldBackgroundColor: Colors.white),
    home: Scaffold(
      body: Column(
        children: [
          Expanded(child: factory()),
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
Widget count: ${_data.size}       FPS: ${silly.fps.toStringAsFixed(1)} ${_isSlow ? 'Slow' : ''}
Times (ms): build ${silly.buildTime.toStringAsFixed(1)}   raster  ${silly.rasterTime.toStringAsFixed(1)}    total ${silly.totalSpan.toStringAsFixed(1)}''';
