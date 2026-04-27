import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:web/web.dart' as web;

import 'app_utils.dart';
import 'frame_silly.dart' as silly;
import 'simple_notifier.dart';

@JS('flutterCanvasKit')
external JSAny? get flutterCanvasKit;

@JS('_flutter_skwasmInstance')
external JSAny? get skwasmInstance;

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
  Widget build(BuildContext context) {
    final currentMode = Uri.base.queryParameters['mode'];
    const validModes = ['canvaskit', 'skwasm', 'skwasm-st', 'wimp'];
    final selectedMode = validModes.contains(currentMode) ? currentMode : null;

    // Detect fallback
    final isCanvasKit = flutterCanvasKit != null;
    final isSkwasm = skwasmInstance != null;

    var isFallback = false;
    if (currentMode == 'skwasm' ||
        currentMode == 'skwasm-st' ||
        currentMode == 'wimp') {
      if (isCanvasKit && !isSkwasm) {
        isFallback = true;
      }
    }

    return MaterialApp(
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: Scaffold(
        body: Column(
          children: [
            Expanded(child: factory()),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DropdownButton<String?>(
                    value: selectedMode,
                    icon: const Text(' ▼'),
                    items: [
                      DropdownMenuItem(
                        child: Text(
                          'Default (${isCanvasKit
                              ? 'CanvasKit'
                              : isSkwasm
                              ? 'Skwasm'
                              : 'Unknown'})',
                        ),
                      ),
                      const DropdownMenuItem(
                        value: 'canvaskit',
                        child: Text('CanvasKit (JS)'),
                      ),
                      DropdownMenuItem(
                        value: 'skwasm',
                        child: Text(
                          currentMode == 'skwasm' && isFallback
                              ? 'Skwasm (Wasm) (Fallback !!)'
                              : 'Skwasm (Wasm)',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'skwasm-st',
                        child: Text(
                          currentMode == 'skwasm-st' && isFallback
                              ? 'Skwasm ST (Wasm) (Fallback !!)'
                              : 'Skwasm ST (Wasm)',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'wimp',
                        child: Text(
                          currentMode == 'wimp' && isFallback
                              ? 'Wimp (Wasm) (Fallback !!)'
                              : 'Wimp (Wasm)',
                        ),
                      ),
                    ],
                    onChanged: (newMode) {
                      final uri = Uri.base;
                      final params = Map<String, String>.from(
                        uri.queryParameters,
                      );
                      if (newMode == null) {
                        params.remove('mode');
                      } else {
                        params['mode'] = newMode;
                      }
                      final newUri = uri.replace(queryParameters: params);
                      web.window.location.href = newUri.toString();
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _notifier,
                      builder: (ctx, child) => Text(_text()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _text() =>
    '''
${_counter == null ? '' : 'Counter: $_counter'}       FPS: ${silly.fps.toStringAsFixed(1)} ${_isSlow ? 'Slow' : ''}
Times (ms): build ${silly.buildTime.toStringAsFixed(1)}   raster  ${silly.rasterTime.toStringAsFixed(1)}    total ${silly.totalSpan.toStringAsFixed(1)}''';
