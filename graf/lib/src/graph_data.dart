import 'dart:collection';

abstract class GraphData<T> {
  Iterable<T> get nodes;
  Iterable<T> edgesFrom(T node);
  bool hasNode(T node);

  factory GraphData(Map<T, Set<T>> values) = _GraphData;

  static GraphData<String> randomRing({int count = 20, int randomBits = 0}) {
    final nodes = List.generate(
      RangeError.checkNotNegative(count, 'count'),
      (i) => 'Node ${i + 1}',
    );

    final map = HashMap<String, Set<String>>.identity();

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      map[node] = HashSet<String>.identity();

      map[node]!.add(nodes[(i + 1) % nodes.length]);

      if (i % 3 == 0) {
        // Add some extra edges
        map[node]!.add(nodes[(i + 2) % nodes.length]);
      }
      if (i % 5 == 0) {
        // Add some more extra edges
        map[node]!.add(nodes[(i + 7) % nodes.length]);
      }
    }

    for (var i = 0; i < randomBits; i++) {
      map['Node ${count + 1 + i}'] = {};
    }

    return GraphData(map);
  }

  static GraphData<String> tree({int count = (1 << 6) - 1}) {
    final nodes = List.generate(
      RangeError.checkNotNegative(count, 'count'),
      (i) => 'Node ${i + 1}',
    );

    final map = HashMap<String, Set<String>>.identity();

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      map[node] = HashSet<String>.identity();

      for (var childIndex in [i * 2 + 1, i * 2 + 2]) {
        if (childIndex < nodes.length) {
          map[node]!.add(nodes[childIndex]);
        }
      }
    }

    return GraphData(map);
  }
}

class _GraphData<T> implements GraphData<T> {
  _GraphData(this._map)
    : assert(
        _map.values.every((targets) => targets.every(_map.containsKey)),
        'All edge target nodes must exist as keys in the input map.',
      );

  final Map<T, Set<T>> _map;

  @override
  Iterable<T> get nodes => _map.keys;

  @override
  Iterable<T> edgesFrom(T node) => _map[node]!;

  @override
  bool hasNode(T node) => _map.containsKey(node);
}
