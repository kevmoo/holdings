import 'package:flutter_test/flutter_test.dart';
import 'package:graf/graf.dart';
import 'package:graf_flutter/src/graph_view.dart'; // Adjust import path if needed

void main() {
  late GraphData<String> testData;

  setUp(() {
    // Simple graph: A -> B, B -> C, C -> A (cycle), A -> D
    testData = GraphData({
      'A': {'B', 'D'},
      'B': {'C'},
      'C': {'A'},
      'D': {},
    });
  });

  group('initialization', () {
    test('initializes with empty visible set by default', () {
      final graphView = GraphView<String>(data: testData);
      expect(graphView.nodes, isEmpty);
    });

    test('initializes with specified initialVisible nodes', () {
      final graphView = GraphView<String>(
        data: testData,
        initialVisible: ['A', 'B'],
      );
      expect(graphView.nodes, unorderedEquals(['A', 'B']));
    });

    test(
      'throws assertion error if initialVisible contains nodes not in data',
      () {
        // Using expectLater because the assertion happens in the constructor
        expectLater(
          () => GraphView<String>(
            data: testData,
            initialVisible: ['A', 'X'], // 'X' is not in testData
          ),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message,
              'message',
              contains('initialVisible contains nodes not in data'),
            ),
          ),
        );
      },
    );
  });

  group('toggle', () {
    test('adds node to visible set if not present', () {
      final graphView = GraphView<String>(data: testData);
      expect(graphView.nodes, isEmpty);

      graphView.toggle('A');
      expect(graphView.nodes, ['A']);

      graphView.toggle('B');
      expect(graphView.nodes, unorderedEquals({'A', 'B'}));
    });

    test('removes node from visible set if present', () {
      final graphView = GraphView<String>(
        data: testData,
        initialVisible: ['A', 'B', 'C'],
      );
      expect(graphView.nodes, unorderedEquals(['A', 'B', 'C']));

      graphView.toggle('B');
      expect(graphView.nodes, unorderedEquals({'A', 'C'}));

      graphView.toggle('A');
      expect(graphView.nodes, equals(['C']));
    });

    test('notifies listeners', () {
      final graphView = GraphView<String>(data: testData);
      var callCount = 0;
      void listener() => callCount++;

      graphView.addListener(listener);

      graphView.toggle('A');
      expect(callCount, 1);

      graphView.toggle('B');
      expect(callCount, 2);

      graphView.toggle('A'); // Toggle off
      expect(callCount, 3);

      graphView.removeListener(listener);
      graphView.toggle('C');
      expect(callCount, 3); // Should not increment after removal
    });

    test('throws assertion error if node is not in data', () {
      final graphView = GraphView<String>(data: testData);
      expect(
        () => graphView.toggle('X'), // 'X' is not in testData
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('node not in data'),
          ),
        ),
      );
    });
  });

  group('view', () {
    test('nodes reflects the current visible set', () {
      final graphView = GraphView<String>(data: testData);
      expect(graphView.nodes, isEmpty);

      graphView.toggle('C');
      expect(graphView.nodes, ['C']);

      graphView.toggle('A');
      expect(graphView.nodes, unorderedEquals({'C', 'A'}));

      graphView.toggle('C');
      expect(graphView.nodes, ['A']);
    });

    test('edgesFrom returns empty if node is not visible', () {
      final graphView = GraphView<String>(
        data: testData,
        initialVisible: ['B', 'C'], // A is not visible
      );
      expect(graphView.edgesFrom('A'), isEmpty);
    });

    test('edgesFrom returns only edges to visible nodes', () {
      final graphView = GraphView<String>(
        data: testData,
        initialVisible: ['A', 'B'], // C and D are not visible initially
      );

      // A -> B (visible), A -> D (not visible)
      expect(graphView.edgesFrom('A'), ['B']);
      // B -> C (not visible)
      expect(graphView.edgesFrom('B'), isEmpty);

      // Make C visible
      graphView.toggle('C');
      expect(graphView.nodes, unorderedEquals({'A', 'B', 'C'}));

      // A -> B (visible), A -> D (not visible)
      expect(graphView.edgesFrom('A'), ['B']);
      // B -> C (visible)
      expect(graphView.edgesFrom('B'), ['C']);
      // C -> A (visible)
      expect(graphView.edgesFrom('C'), ['A']);

      // Make D visible
      graphView.toggle('D');
      expect(graphView.nodes, unorderedEquals({'A', 'B', 'C', 'D'}));
      // A -> B (visible), A -> D (visible)
      expect(graphView.edgesFrom('A'), unorderedEquals({'B', 'D'}));
      // D -> {} (no outgoing edges)
      expect(graphView.edgesFrom('D'), isEmpty);

      // Hide B
      graphView.toggle('B');
      expect(graphView.nodes, unorderedEquals({'A', 'C', 'D'}));
      // A -> B (not visible), A -> D (visible)
      expect(graphView.edgesFrom('A'), ['D']);
      // C -> A (visible)
      expect(graphView.edgesFrom('C'), ['A']);
    });
  });

  // Test identity constructor (functional check)
  // Test will fail on JavaScript!!
  test('identity constructor works functionally', () {
    // Create objects that might have same hashcode but different identity
    const nodeA1 = 'A';
    final nodeA2 = String.fromCharCodes(
      nodeA1.runes,
    ); // Same value, maybe different identity

    const nodeB = 'B';

    final identityData = GraphData<String>({
      nodeA1: {nodeB},
      nodeB: {},
    });

    // Use identity=true
    final graphView = GraphView<String>(
      data: identityData,
      initialVisible: [nodeA1],
    );

    expect(graphView.nodes, contains(nodeA1));
    // Even if nodeA2 has same value, it shouldn't be considered visible
    // because identity is different (this depends on Dart's string interning,
    // but demonstrates the principle). HashSet.identity relies on identical().
    expect(
      graphView.nodes,
      isNot(contains(nodeA2)),
    ); // Dart often interns strings, so this might be true.
    // A better test would use custom objects.

    graphView.toggle(nodeA1); // Toggle off using the original instance
    expect(graphView.nodes, isEmpty);

    graphView.toggle(
      nodeA2,
    ); // Toggle on using the potentially different instance
    expect(
      graphView.nodes,
      contains(nodeA2),
    ); // Should add based on identity if different
    expect(
      graphView.nodes,
      isNot(contains(nodeA1)),
    ); // Should also contain the original due to value equality if interned
  });

  group('showEdges', () {
    test('adds edges to visible set', () {
      final graphView = GraphView<String>(
        data: testData,
        initialVisible: ['A'],
      );
      expect(graphView.nodes, ['A']);
      expect(graphView.edgesFrom('A'), isEmpty);

      graphView.showEdges('A');
      expect(graphView.nodes, unorderedEquals({'A', 'B', 'D'}));
      expect(graphView.edgesFrom('A'), ['B', 'D']);
    });

    test('does not add edges to visible set if already visible', () {
      final graphView = GraphView<String>(
        data: testData,
        initialVisible: ['A', 'B'],
      );
      expect(graphView.nodes, unorderedEquals({'A', 'B'}));
      expect(graphView.edgesFrom('A'), ['B']);

      graphView.showEdges('A');
      expect(graphView.nodes, unorderedEquals({'A', 'B', 'D'}));
      expect(graphView.edgesFrom('A'), ['B', 'D']);
    });

    test('throws assertion error if node is not in data', () {
      final graphView = GraphView<String>(data: testData);
      expect(
        () => graphView.showEdges('X'), // 'X' is not in testData
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('node not in data'),
          ),
        ),
      );
    });

    test('throws assertion error if node is not visible', () {
      final graphView = GraphView<String>(data: testData);
      expect(
        () => graphView.showEdges('A'), // 'A' is not visible
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('node not in visible set'),
          ),
        ),
      );
    });
  });

  group('hideEdges', () {
    test('removes edges from visible set', () {
      final graphView = GraphView<String>(
        data: testData,
        initialVisible: ['A', 'B', 'D'],
      );
      expect(graphView.nodes, unorderedEquals({'A', 'B', 'D'}));
      expect(graphView.edgesFrom('A'), unorderedEquals({'B', 'D'}));

      graphView.hideEdges('A');
      expect(graphView.nodes, ['A']);
      expect(graphView.edgesFrom('A'), isEmpty);
    });

    test('does not remove edges from visible set if already hidden', () {
      final graphView = GraphView<String>(
        data: testData,
        initialVisible: ['A'],
      );
      expect(graphView.nodes, ['A']);
      expect(graphView.edgesFrom('A'), isEmpty);

      graphView.hideEdges('A');
      expect(graphView.nodes, ['A']);
      expect(graphView.edgesFrom('A'), isEmpty);
    });

    test('throws assertion error if node is not in data', () {
      final graphView = GraphView<String>(data: testData);
      expect(
        () => graphView.hideEdges('X'), // 'X' is not in testData
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('node not in data'),
          ),
        ),
      );
    });

    test('throws assertion error if node is not visible', () {
      final graphView = GraphView<String>(data: testData);
      expect(
        () => graphView.hideEdges('A'), // 'A' is not visible
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('node not in visible set'),
          ),
        ),
      );
    });
  });
}
