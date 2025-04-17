import 'graph_data.dart';

extension GraphDataExtensions<T> on GraphData<T> {
  bool hasEdge(T from, T to) =>
      edgesFrom(from).contains(to) || edgesFrom(to).contains(from);

  List<T> getPredecessors(T node) {
    final predecessors = <T>[];
    for (var key in nodes) {
      final value = edgesFrom(key);
      if (value.contains(node)) {
        predecessors.add(key);
      }
    }
    return predecessors;
  }

  Iterable<({T from, T to})> get edges =>
      nodes.expand((n) => edgesFrom(n).map((toNode) => (from: n, to: toNode)));
}
