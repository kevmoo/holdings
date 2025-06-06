import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:stats/stats.dart';

typedef DemoStuff = ({
  Widget Function() factory,
  int? Function(double fps, bool isSlow) timerCallback,
});

({num buildDuration, num rasterDuration, num overhead, num totalSpan})
allTheStats(Iterable<FrameTiming> timings) => (
  buildDuration: timings.map((e) => e.buildDuration.inMicroseconds).mean / 1000,
  rasterDuration:
      timings.map((e) => e.rasterDuration.inMicroseconds).mean / 1000,
  overhead: timings.map((e) => e.vsyncOverhead.inMicroseconds).mean / 1000,
  totalSpan: timings.map((e) => e.totalSpan.inMicroseconds).mean / 1000,
);
