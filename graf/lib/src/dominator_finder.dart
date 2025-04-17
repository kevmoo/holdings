// ignore_for_file: lines_longer_than_80_chars

import 'dart:collection';

import 'graph_data.dart';
import 'graph_extensions.dart';

class DominatorFinder<T> {
  final GraphData<T> graph;
  final T entryNode;
  final _dominators = HashMap<T, Set<T>>();
  final _immediateDominators = HashMap<T, T?>();

  DominatorFinder._(this.graph, this.entryNode);

  static DominatorFinder<T> compute<T>(GraphData<T> graph, T entryNode) =>
      DominatorFinder._(graph, entryNode).._computeDominators();

  /// Computes the dominators and immediate dominators for each node.
  void _computeDominators() {
    // Initialize dominator sets
    for (var node in graph.nodes) {
      if (node == entryNode) {
        _dominators[node] = {node};
      } else {
        _dominators[node] = graph.nodes.toSet();
      }
    }

    // Iteratively compute dominator sets
    var changed = true;
    while (changed) {
      changed = false;
      for (var node in graph.nodes) {
        if (node == entryNode) continue;

        Set<T> predecessorsDominatorsIntersection;
        final predecessors = graph.getPredecessors(node);

        if (predecessors.isNotEmpty) {
          predecessorsDominatorsIntersection = Set.of(
            _dominators[predecessors.first]!,
          );
          for (var i = 1; i < predecessors.length; i++) {
            predecessorsDominatorsIntersection =
                predecessorsDominatorsIntersection.intersection(
                  _dominators[predecessors[i]]!,
                );
          }
        } else {
          // If a node has no predecessors (and is not the entry),
          // it's likely unreachable from the entry, or the graph is just that simple.
          // Its dominator set would ideally be just itself if reachable only from entry,
          // but in the iterative approach, we rely on predecessor intersections.
          // For simplicity in this iterative method, we'll treat unreachable nodes'
          // dominators as the set of all nodes initially, and the intersection
          // with an empty set of predecessors (if not entry) effectively keeps it large
          // until predecessors are processed. A more robust approach might involve
          // a reachability analysis first.
          predecessorsDominatorsIntersection = graph.nodes.toSet();
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
    _immediateDominators[entryNode] =
        null; // Entry node has no immediate dominator

    for (var node in graph.nodes) {
      if (node == entryNode) continue;

      final nodeDominators = _dominators[node];
      if (nodeDominators == null || nodeDominators.isEmpty) {
        // This node might be unreachable from the entry.
        _immediateDominators[node] = null;
        continue;
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

          if (_dominators[dominator]!.length > maxDominatorSetSize) {
            maxDominatorSetSize = _dominators[dominator]!.length;
            immediateDominatorCandidate = dominator;
          }
        }
      }
      _immediateDominators[node] = immediateDominatorCandidate;
    }
  }

  // Get the dominator set for a node
  Set<T>? getDominators(T node) => _dominators[node];

  // Get the immediate dominator for a node
  T? getImmediateDominator(T node) => _immediateDominators[node];
}
