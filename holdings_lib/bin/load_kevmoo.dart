import 'dart:collection';
import 'dart:io';

import 'package:dart2js_info/binary_serialization.dart';
import 'package:dart2js_info/info.dart';
import 'package:graf/graf.dart';

const _path =
    '/Users/kevmoo/github/kevmoo/kevmoo.com/build/web/main.dart2js.js.info.data';

Future<void> main(List<String> args) async {
  final dataFile = File(_path);

  final info = decode(dataFile.readAsBytesSync());

  final visited = <Info>{};
  final toVisit = ListQueue<Info>();

  final map = <Info, Set<Info>>{};

  final entry = info.program!.entrypoint;
  toVisit.add(entry);

  void status() {
    print('''
Graph size: ${map.length}
To visit:   ${toVisit.length}
Visited:    ${visited.length}
''');
  }

  final timer = Stopwatch()..start();
  while (toVisit.isNotEmpty) {
    if (timer.elapsed > const Duration(seconds: 3)) {
      status();
      timer.reset();
    }

    final current = toVisit.removeFirst();

    if (visited.contains(current)) {
      continue;
    }

    if (current is CodeInfo) {
      for (var use in current.uses) {
        (map[current] ??= {}).add(use.target);
        toVisit.add(use.target);
      }
    }

    visited.add(current);
  }

  status();

  final graph = GraphData(map);
  final dominatorFinder = DominatorFinder.compute<Info>(graph, entry);

  print('Dominator Sets:');
  for (var node in graph.nodes) {
    print('$node: ${dominatorFinder.getDominators(node)}');
  }

  print('\nImmediate Dominators:');
  for (var node in graph.nodes) {
    print('$node: ${dominatorFinder.getImmediateDominator(node)}');
  }
}
