import 'dart:typed_data';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

// TODO: this is BAD. Global state bad!
double fps = 0;
int targetGraphSize = 0;
int actualGraphSize = 0;

class FrameSilly extends StatefulWidget {
  const FrameSilly();

  @override
  State<FrameSilly> createState() => _FrameSillyState();
}

class _FrameSillyState extends State<FrameSilly>
    with SingleTickerProviderStateMixin {
  static const _maxUpdateDelta = Duration(milliseconds: 200);
  late Ticker _ticker;

  final _frameTimes = Uint32List(60 * 5);
  Duration _lastTick = Duration.zero;
  Duration _lastBuildRequest = Duration.zero;
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
      print('long frame! $delta');
      return;
    } else if (delta == Duration.zero) {
      print('zero frame!');
      return;
    }

    final lastValue = _frameTimes[_index];

    if (lastValue == 0) {
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
    fps = Duration.microsecondsPerSecond / (_frameSum / _count);

    if (_lastTick - _lastBuildRequest > _maxUpdateDelta) {
      _lastBuildRequest = _lastTick;
      setState(() {});
    }
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
      'Size: $targetGraphSize '
      'Target: $actualGraphSize '
      'FPS: ${fps.toStringAsFixed(2)}',
      style: const TextStyle(fontFamily: 'monospace'),
      textAlign: TextAlign.start,
    ),
  );
}
