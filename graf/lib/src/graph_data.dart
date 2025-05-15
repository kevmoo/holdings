abstract class GraphData<T> {
  Iterable<T> get nodes;
  Iterable<T> edgesFrom(T node);
  bool hasNode(T node);

  factory GraphData(Map<T, Iterable<T>> values) = _GraphData;
}

class _GraphData<T> implements GraphData<T> {
  _GraphData(this._map)
    : assert(
        _map.values.every((targets) => targets.every(_map.containsKey)),
        'All edge target nodes must exist as keys in the input map.',
      );

  final Map<T, Iterable<T>> _map;

  @override
  Iterable<T> get nodes => _map.keys;

  @override
  Iterable<T> edgesFrom(T node) => _map[node]!;

  @override
  bool hasNode(T node) => _map.containsKey(node);
}
