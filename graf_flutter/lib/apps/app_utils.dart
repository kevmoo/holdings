import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:stats/stats.dart';

typedef DemoStuff = ({
  Widget Function() factory,
  void Function(double fps, bool isSlow) timerCallback,
});

({num buildDuration, num rasterDuration, num overhead, num totalSpan})
allTheStats(Iterable<FrameTiming> timings) => (
  buildDuration:
      LightStats<int>.fromData(
        timings.map((e) => e.buildDuration.inMicroseconds),
      ).average /
      1000,
  rasterDuration:
      LightStats<int>.fromData(
        timings.map((e) => e.rasterDuration.inMicroseconds),
      ).average /
      1000,
  overhead:
      LightStats<int>.fromData(
        timings.map((e) => e.vsyncOverhead.inMicroseconds),
      ).average /
      1000,
  totalSpan:
      LightStats<int>.fromData(
        timings.map((e) => e.totalSpan.inMicroseconds),
      ).average /
      1000,
);
