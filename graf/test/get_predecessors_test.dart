// test/graph_extensions_test.dart
import 'package:graf/graf.dart';
import 'package:test/test.dart';

void main() {
  group('GraphDataExtensions', () {
    group('connectedComponents', () {
      test('should return a single component for a fully connected graph', () {
        // Graph: A <-> B <-> C <-> A
        final map = <String, Set<String>>{
          'A': {'B', 'C'},
          'B': {'A', 'C'},
          'C': {'A', 'B'},
        };
        final graph = GraphData(map);
        final components = graph.connectedComponents();
        expect(components.first, unorderedEquals(['A', 'B', 'C']));
      });

      test('should return multiple components for a disconnected graph', () {
        // Graph: A <-> B, C <-> D
        final map = <String, Set<String>>{
          'A': {'B'},
          'B': {'A'},
          'C': {'D'},
          'D': {'C'},
        };
        final graph = GraphData(map);
        final components = graph.connectedComponents();
        expect(
          components,
          unorderedEquals([
            ['A', 'B'],
            ['C', 'D'],
          ]),
        );
      });

      test('should handle isolated nodes as separate components', () {
        // Graph: A, B, C (all isolated)
        final map = <String, Set<String>>{'A': {}, 'B': {}, 'C': {}};
        final graph = GraphData(map);
        final components = graph.connectedComponents();
        expect(
          components,
          unorderedEquals([
            ['A'],
            ['B'],
            ['C'],
          ]),
        );
      });

      test('should work with a mix of connected and isolated nodes', () {
        // Graph: A <-> B, C (isolated)
        final map = <String, Set<String>>{
          'A': {'B'},
          'B': {'A'},
          'C': {},
        };
        final graph = GraphData(map);
        final components = graph.connectedComponents();
        expect(
          components,
          unorderedEquals([
            ['A', 'B'],
            ['C'],
          ]),
        );
      });

      test('should handle pyramids', () {
        // Graph: A <-> B, C (isolated)
        final map = <String, Set<String>>{
          'A': {'B'},
          'C': {'B'},
          'B': {},
        };
        final graph = GraphData(map);
        final components = graph.connectedComponents();

        expect(
          components,
          unorderedEquals([
            ['A', 'B', 'C'],
          ]),
        );
      });
    });
    // --- New tests for hasEdge ---
    group('hasEdge', () {
      test('should return true if edge exists from -> to', () {
        // Graph: A -> B
        final map = <String, Set<String>>{
          'A': {'B'},
          'B': {},
        };
        final graph = GraphData(map);
        expect(graph.hasEdge('A', 'B'), isTrue);
      });

      test('should return true if edge exists to -> from', () {
        // Graph: B -> A
        final map = <String, Set<String>>{
          'A': {},
          'B': {'A'},
        };
        final graph = GraphData(map);
        expect(graph.hasEdge('A', 'B'), isTrue);
      });

      test('should return true if edge exists in both directions', () {
        // Graph: A <-> B
        final map = <String, Set<String>>{
          'A': {'B'},
          'B': {'A'},
        };
        final graph = GraphData(map);
        expect(graph.hasEdge('A', 'B'), isTrue);
        expect(
          graph.hasEdge('B', 'A'),
          isTrue,
        ); // Also check the reverse explicitly
      });

      test('should return false if no edge exists between nodes', () {
        // Graph: A -> B, C -> D
        final map = <String, Set<String>>{
          'A': {'B'},
          'B': {},
          'C': {'D'},
          'D': {},
        };
        final graph = GraphData(map);
        expect(graph.hasEdge('A', 'C'), isFalse);
        expect(graph.hasEdge('B', 'D'), isFalse);
        expect(graph.hasEdge('A', 'D'), isFalse);
      });

      test('should return false for isolated nodes', () {
        // Graph: A, B
        final map = <String, Set<String>>{'A': {}, 'B': {}};
        final graph = GraphData(map);
        expect(graph.hasEdge('A', 'B'), isFalse);
      });

      test('should return true for self-loops if they exist', () {
        // Graph: A -> A, B
        final map = <String, Set<String>>{
          'A': {'A'},
          'B': {},
        };
        final graph = GraphData(map);
        expect(graph.hasEdge('A', 'A'), isTrue);
        expect(graph.hasEdge('B', 'B'), isFalse); // No self-loop on B
      });

      test('should work with a slightly more complex graph', () {
        // Graph: Entry -> A -> {B, C}, B -> D, C -> D, D -> {Exit, A}
        final map = <String, Set<String>>{
          'Entry': {'A'},
          'A': {'B', 'C'},
          'B': {'D'},
          'C': {'D'},
          'D': {'Exit', 'A'},
          'Exit': {}, // Exit must exist
        };
        final graph = GraphData(map);

        expect(graph.hasEdge('Entry', 'A'), isTrue);
        expect(graph.hasEdge('A', 'Entry'), isTrue); // Because Entry->A exists
        expect(graph.hasEdge('A', 'B'), isTrue);
        expect(graph.hasEdge('B', 'A'), isTrue); // Because A->B exists
        expect(graph.hasEdge('B', 'C'), isFalse);
        expect(graph.hasEdge('A', 'D'), isTrue); // Because D->A exists
        expect(graph.hasEdge('D', 'A'), isTrue);
        expect(graph.hasEdge('D', 'Exit'), isTrue);
        expect(graph.hasEdge('Exit', 'D'), isTrue); // Because D->Exit exists
        expect(graph.hasEdge('Entry', 'Exit'), isFalse);
      });
    });
    // --- End of new tests ---

    group('getPredecessors', () {
      test('should return an empty list for a node with no predecessors', () {
        // Graph: B -> C, A (isolated)
        final map = <String, Set<String>>{
          'A': {},
          'B': {'C'},
          'C': {}, // C must exist as a node if it's a target
        };
        final graph = GraphData(map);

        expect(graph.getPredecessors('A'), isEmpty);
      });

      test('should return the correct single predecessor', () {
        // Graph: A -> B, C -> D
        final map = <String, Set<String>>{
          'A': {'B'},
          'B': {}, // B must exist
          'C': {'D'},
          'D': {}, // D must exist
        };
        final graph = GraphData(map);

        expect(graph.getPredecessors('B'), equals(['A']));
      });

      test('should return multiple predecessors', () {
        // Graph: A -> D, B -> D, C -> D, D -> E
        final map = <String, Set<String>>{
          'A': {'D'},
          'B': {'D'},
          'C': {'D'},
          'D': {'E'},
          'E': {}, // E must exist
        };
        final graph = GraphData(map);
        final predecessors = graph.getPredecessors('D');

        // The order depends on the iteration order of graph.nodes
        // Using unorderedEquals is safer if the order isn't guaranteed or
        // critical
        expect(predecessors, unorderedEquals(['A', 'B', 'C']));
      });

      test('should handle cycles correctly', () {
        // Graph: A -> B -> C -> A, D -> A
        final map = <String, Set<String>>{
          'A': {'B'},
          'B': {'C'},
          'C': {'A'},
          'D': {'A'},
        };
        final graph = GraphData(map);
        final predecessors = graph.getPredecessors('A');

        expect(predecessors, unorderedEquals(['C', 'D']));
      });

      test('should return an empty list for the only node in the graph', () {
        // Graph: Solo (isolated)
        final map = <String, Set<String>>{'Solo': {}};
        final graph = GraphData(map);

        expect(graph.getPredecessors('Solo'), isEmpty);
      });

      test('should work with a slightly more complex graph', () {
        // Graph: Entry -> A -> {B, C}, B -> D, C -> D, D -> {Exit, A}
        final map = <String, Set<String>>{
          'Entry': {'A'},
          'A': {'B', 'C'},
          'B': {'D'},
          'C': {'D'},
          'D': {'Exit', 'A'},
          'Exit': {}, // Exit must exist
        };
        final graph = GraphData(map);

        expect(graph.getPredecessors('Entry'), isEmpty);
        expect(graph.getPredecessors('A'), unorderedEquals(['Entry', 'D']));
        expect(graph.getPredecessors('B'), equals(['A']));
        expect(graph.getPredecessors('C'), equals(['A']));
        expect(graph.getPredecessors('D'), unorderedEquals(['B', 'C']));
        expect(graph.getPredecessors('Exit'), equals(['D']));
      });
    });

    // You can add tests for the `edges` getter here as well
    group('edges getter', () {
      test('should return all edges as tuples', () {
        // Graph: A -> {B, C}, B -> D
        final map = <String, Set<String>>{
          'A': {'B', 'C'},
          'B': {'D'},
          'C': {}, // C must exist
          'D': {}, // D must exist
        };
        final graph = GraphData(map);
        final edges = graph.edges.toSet(); // Use toSet for unordered comparison

        expect(
          edges,
          equals({
            (from: 'A', to: 'B'),
            (from: 'A', to: 'C'),
            (from: 'B', to: 'D'),
          }),
        );
      });

      test('should return empty iterable for graph with no edges', () {
        // Graph: A, B (isolated)
        final map = <String, Set<String>>{'A': {}, 'B': {}};
        final graph = GraphData(map);
        expect(graph.edges, isEmpty);
      });
    });
  });
}
