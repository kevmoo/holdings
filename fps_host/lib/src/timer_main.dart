import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app_utils.dart';
import 'frame_silly.dart' as silly;
import 'simple_notifier.dart';

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

    _counter = demoStuff.timerCallback(silly.fps, _isSlow);

    _notifier.notify();
  }

  Timer.periodic(Duration(milliseconds: _isSlow ? 500 : 200), onTimer);
}

int? _counter;

void _onTimings(List<FrameTiming> timings) {
  _timings.addAll(timings);
}

final _isSlow = Uri.base.queryParameters.containsKey('slow');

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
${_counter == null ? '' : 'Counter: $_counter'}       FPS: ${silly.fps.toStringAsFixed(1)} ${_isSlow ? 'Slow' : ''}
Times (ms): build ${silly.buildTime.toStringAsFixed(1)}   raster  ${silly.rasterTime.toStringAsFixed(1)}    total ${silly.totalSpan.toStringAsFixed(1)}''';
