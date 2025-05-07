import 'dart:ui';

import 'package:stats/stats.dart';

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
