import 'graph_data.dart';

extension GraphDataExtensions<T> on GraphData<T> {
  bool hasEdge(T node1, T node2) =>
      edgesFrom(node1).contains(node2) || edgesFrom(node2).contains(node1);

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
