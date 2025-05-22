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

  final dominatorFinder = DominatorFinder.compute(
    graph,
    info.program!.entrypoint,
    predecessorsFunction: _cachingPredecessorFunc,
  );

  print('Dominator size: ${dominatorFinder.size}');

  final immediateFun = HashMap<Info, HashSet<Info>>.identity();

  for (var node in graph.nodes) {
    final immediate = dominatorFinder.getImmediateDominator(node);

    if (immediate == null) {
      continue;
    }

    immediateFun.putIfAbsent(immediate, HashSet.new).add(node);
  }

  final toStringBits = immediateFun.entries
      .where((me) => me.key.name == 'toString')
      .toList();

  toStringBits.sort((a, b) => -a.value.length.compareTo(b.value.length));

  print(toStringBits);
}
