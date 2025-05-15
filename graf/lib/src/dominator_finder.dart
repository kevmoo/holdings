// ignore_for_file: lines_longer_than_80_chars

import 'dart:collection';

import 'graph_data.dart';
import 'graph_extensions.dart';

List<T> _defaultFunc<T>(GraphData<T> graph, T node) =>
    graph.getPredecessors(node);

class DominatorFinder<T> {
  final GraphData<T> graph;
  final T entryNode;
  final _dominators = HashMap<T, Set<T>>();
  final _immediateDominators = HashMap<T, T?>();
  final List<T> Function(GraphData<T> graph, T entryNode) _predecessorFunc;

  DominatorFinder._(this.graph, this.entryNode, this._predecessorFunc);

  static DominatorFinder<T> compute<T>(
    GraphData<T> graph,
    T entryNode, {
    List<T> Function(GraphData<T> graph, T entryNode)? predecessorsFunction,
  }) =>
      DominatorFinder._(graph, entryNode, predecessorsFunction ?? _defaultFunc)
        .._computeDominators();

  /// Computes the dominators and immediate dominators for each node.
  void _computeDominators() {
    final toVisit = ListQueue<T>()..add(entryNode);

    while (toVisit.isNotEmpty) {
      final node = toVisit.removeFirst();

      if (node == entryNode) {
        _dominators[node] = {node};
      } else {
        _dominators[node] = const {};
      }

      toVisit.addAll(
        graph.edgesFrom(node).where((e) => !_dominators.containsKey(e)),
      );
    }

    // Iteratively compute dominator sets
    var changed = true;
    while (changed) {
      changed = false;
      for (var node in _dominators.keys) {
        if (node == entryNode) continue;

        final predecessors =
            _predecessorFunc(
              graph,
              node,
            ).where(_dominators.containsKey).toList();

        var predecessorsDominatorsIntersection = Set.of(
          _dominators[predecessors.first]!,
        );
        for (var i = 1; i < predecessors.length; i++) {
          predecessorsDominatorsIntersection =
              predecessorsDominatorsIntersection.intersection(
                _dominators[predecessors[i]]!,
              );
        }

        final newDominators = <T>{node, ...predecessorsDominatorsIntersection};

        if (!_dominators[node]!.containsAll(newDominators) ||
            !newDominators.containsAll(_dominators[node]!)) {
          _dominators[node] = newDominators;
          changed = true;
        }
      }
    }

    // Compute immediate dominators

    _computeImmediateDominators();
  }

  /// Computes the immediate dominators from the dominator sets.
  void _computeImmediateDominators() {
    for (var node in _dominators.keys) {
      if (node == entryNode) continue;

      final nodeDominators = _dominators[node];
      if (nodeDominators == null || nodeDominators.isEmpty) {
        // This node is unreachable from the entry.
        throw StateError('Something is likely wrong with the algorithm');
      }

      // The immediate dominator is the dominator that is not
      // strictly dominated by any other dominator of the node.
      // In the dominator tree, it's the parent.
      // We can find it by looking for the dominator that dominates
      // the current node but doesn't dominate any other dominator
      // of the current node (except itself).

      T? immediateDominatorCandidate;
      var maxDominatorSetSize = -1;

      for (var dominator in nodeDominators) {
        if (dominator == node) continue;

        // Check if this dominator is strictly dominated by any other dominator of node
        var isStrictlyDominatedByAnotherDominator = false;
        for (var otherDominator in nodeDominators) {
          if (otherDominator == node || otherDominator == dominator) continue;

          if (_dominators[otherDominator]!.contains(dominator)) {
            isStrictlyDominatedByAnotherDominator = true;
            break;
          }
        }

        if (!isStrictlyDominatedByAnotherDominator) {
          // This dominator is a potential immediate dominator.
          // If there are multiple such candidates (which shouldn't happen in a valid dominator tree),
          // the one that dominates the most other nodes (besides the current one)
          // would be closer to the entry. However, the definition guarantees a unique immediate dominator.
          // A simpler way for the iterative approach is to find the dominator
          // (excluding the node itself) with the largest dominator set, as it will be highest in the dominator lattice
          // and thus closest to the node in the dominator tree.

          final theLength = _dominators[dominator]!.length;
          if (theLength > maxDominatorSetSize) {
            maxDominatorSetSize = theLength;
            immediateDominatorCandidate = dominator;
          }
        }
      }

      if (immediateDominatorCandidate != null) {
        _immediateDominators[node] = immediateDominatorCandidate;
      }
    }
  }

  /// The size of the graph excluding nodes unreachable from [entryNode].
  int get size => _dominators.length;

  Iterable<T> get nodes => _dominators.keys;

  // Get the dominator set for a node
  Set<T>? getDominators(T node) => _dominators[node];

  // Get the immediate dominator for a node
  T? getImmediateDominator(T node) => _immediateDominators[node];
}
