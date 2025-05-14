import 'package:graf/graf.dart';
import 'package:holdings_lib/holdings_lib.dart';

Future<void> main() async {
  final info = await load();

  final graph = DumpInfoGraph(info: info);

  print(graph.nodes.length);

  final bob = DominatorFinder.compute(graph, info.program!.entrypoint);

  print(bob.getDominators(info.program!.entrypoint));
}
