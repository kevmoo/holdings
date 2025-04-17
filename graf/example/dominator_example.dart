import 'package:graf/graf.dart';

void main() {
  final cfg = GraphData(<String, Set<String>>{
    'Entry': {'A'},
    'A': {'B', 'C'},
    'B': {'D'},
    'C': {'D'},
    'D': {'Exit'},
    'Exit': {},
  });

  final dominatorFinder = DominatorFinder.compute(cfg, 'Entry');

  print('Dominator Sets:');
  for (var node in cfg.nodes) {
    print('$node: ${dominatorFinder.getDominators(node)}');
  }

  print('\nImmediate Dominators:');
  for (var node in cfg.nodes) {
    print('$node: ${dominatorFinder.getImmediateDominator(node)}');
  }
}
