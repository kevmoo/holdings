import 'dart:collection';

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

  Set<Set<T>> connectedComponents() {
    final visited = HashSet<T>();
    final components = HashSet<HashSet<T>>();

    void depthFirstSearch(T node, Set<T> component) {
      visited.add(node);
      component.add(node);

      for (final neighbor in edgesFrom(node)) {
        if (visited.contains(neighbor)) {
          if (component.contains(neighbor)) {
            continue;
          }

          final existingComponents =
              components.where((e) => e.contains(neighbor)).toList();

          for (var existing in existingComponents) {
            components.remove(existing);
            component.addAll(existing);
          }
        } else {
          depthFirstSearch(neighbor, component);
        }
      }
    }

    for (final node in nodes) {
      if (!visited.contains(node)) {
        final component = HashSet<T>();
        depthFirstSearch(node, component);

        final added = components.add(component);
        assert(added);
      }
    }

    return components;
  }
}
