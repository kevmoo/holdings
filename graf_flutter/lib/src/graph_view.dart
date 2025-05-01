import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:graf/graf.dart';

class GraphView<T> implements Listenable, GraphData<T> {
  /// If [identity] is `true`, use Object `identity`. This can be faster, but
  /// should be used carefully and consistently with the behavior of [data].
  GraphView({
    required this.data,
    bool identity = true,
    Iterable<T> initialVisible = const [],
  }) : _visible = identity ? HashSet<T>.identity() : HashSet<T>() {
    _visible.addAll(initialVisible);
    assert(
      _visible.every(data.nodes.contains),
      'initialVisible contains nodes not in data',
    );
  }

  final GraphData<T> data;
  final Set<T> _visible;
  final _notifier = _MyNotifier();

  void toggle(T node) {
    assert(data.nodes.contains(node), 'node not in data');
    if (!_visible.add(node)) {
      _visible.remove(node);
    }
    _notifier._notify();
  }

  void showEdges(T node) {
    assert(data.nodes.contains(node), 'node not in data');
    assert(_visible.contains(node), 'node not in visible set');
    final before = _visible.length;
    _visible.addAll(data.edgesFrom(node));
    if (_visible.length != before) {
      _notifier._notify();
    }
  }

  void hideEdges(T node) {
    assert(data.nodes.contains(node), 'node not in data');
    assert(_visible.contains(node), 'node not in visible set');

    final before = _visible.length;
    _visible.removeAll(data.edgesFrom(node));

    if (_visible.length != before) {
      _notifier._notify();
    }
  }

  @override
  void addListener(VoidCallback listener) => _notifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _notifier.removeListener(listener);

  @override
  Iterable<T> edgesFrom(T node) => _visible.contains(node)
      ? data.edgesFrom(node).where(_visible.contains)
      : const [];

  @override
  Iterable<T> get nodes => _visible;

  @override
  bool hasNode(T node) => _visible.contains(node);
}

// Avoiding the lint about calling `notifyListeners` being protected/test only.
final class _MyNotifier extends ChangeNotifier {
  void _notify() => notifyListeners();
}
