import 'dart:collection';

import 'package:graf/graf.dart';
import 'package:graphs/graphs.dart';
import 'package:holdings_lib/holdings_lib.dart';
import 'package:holdings_lib/src/sample_files.dart';

final _expando = Expando<List<Info>>('predecessors');

List<Info> _cachingPredecessorFunc(GraphData<Info> graph, Info node) =>
    _expando[node] ??= graph.getPredecessors(node);

Future<void> main() async {
  final info = await load(counterInfo);

  final graph = DumpInfoGraph(info: info);

  print('Input graph size: ${graph.nodes.length}');

  final connectedComponents = stronglyConnectedComponents(
    graph.nodes,
    graph.edgesFrom,
  );

  final lengthToCount = <int, Set<Iterable<Info>>>{};

  for (var comp in connectedComponents) {
    lengthToCount.putIfAbsent(comp.length, HashSet.new).add(comp);
  }

  print('****');
  print(
    (lengthToCount.entries.map((e) => MapEntry(e.key, e.value.length)).toList()
          ..sort((a, b) => -a.key.compareTo(b.key)))
        .join('\n'),
  );

  print('ugh - starting slow stuff');

  final bob = DominatorFinder.compute(
    graph,
    info.program!.entrypoint,
    predecessorsFunction: _cachingPredecessorFunc,
  );

  print('Dominator size: ${bob.size}');

  final weird = <Info>[];
  final notZero = <CodeInfo>[];

  for (var node in graph.nodes) {
    if (bob.getDominators(node) == null) {
      weird.add(node);
      if (node is CodeInfo) {
        if (node.size > 0) {
          notZero.add(node);
        }
      }
    }
  }

  print('items that have no dominator');
  print(weird.length);
  print('items with no dominator that are non-empty');
  print(notZero.length);

  final visited = <Info>[];

  final toVisit = ListQueue<Info>()..add(notZero.first);
  while (toVisit.isNotEmpty) {
    final node = toVisit.removeFirst();
    visited.add(node);
    final preds = graph.getPredecessors(node);
    print(visited.length);
    print(visited);
    toVisit.addAll(preds.where((pred) => !visited.contains(pred)));
  }

  final result = shortestPath(
    info.program!.entrypoint,
    weird.last,
    graph.edgesFrom,
  );

  print(result?.toList());
}
