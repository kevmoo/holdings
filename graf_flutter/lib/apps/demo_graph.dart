// ignore_for_file: lines_longer_than_80_chars

import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:fps_host/fps_host.dart';
import 'package:graf/graf.dart';

enum DemoGraphDeltaOption { addNode, removeNode, addEdge, removeEdge }

final _rnd = Random();

const _maxDelta = 3;
const _maxTries = 100;

const _edgeStuff = false;

class DemoGraph implements GraphData<int>, Listenable {
  DemoGraph({int targetCount = 20}) {
    _targetCount = targetCount;
    for (var i = 0; i < targetCount; i++) {
      _map[i] = _createEmpty();
    }

    if (_edgeStuff) {
      for (var i = 0; i < (targetCount - 1); i++) {
        var added = false;
        do {
          final a = _rnd.nextInt(targetCount);
          final b = _rnd.nextInt(targetCount);
          added = a != b && !_map[b]!.contains(a) && _map[a]!.add(b);
        } while (!added);
      }

      assert(edges.length == (targetCount - 1));
    }
  }

  final Map<int, Set<int>> _map = HashMap<int, Set<int>>();

  late int _targetCount;

  int get targetCount => _targetCount;

  set targetCount(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'Cannot be negative');
    }
    _targetCount = value;
  }

  final _notifier = SimpleNotifier();

  int get size => _map.length;

  Set<int> _createEmpty() => _edgeStuff ? HashSet<int>() : const {};

  DemoGraphDeltaOption churn() {
    final edgeCount = edges.length;
    final edgeDelta = (_targetCount - 1) - edgeCount;
    final nodeDelta = _targetCount - _map.length;

    final churnOptions = <DemoGraphDeltaOption>[];

    if (nodeDelta > -_maxDelta) {
      // we can add nodes – but no more than _maxDelta
      churnOptions.addAll(
        Iterable.generate(
          min(max(nodeDelta, 1), _maxDelta),
          (i) => DemoGraphDeltaOption.addNode,
        ),
      );
    }

    if (_edgeStuff &&
        edgeDelta > -_maxDelta &&
        _map.length > 1 &&
        edgeCount < (_targetCount - 1)) {
      // we can add edges – but no more than _maxDelta
      churnOptions.addAll(
        Iterable.generate(
          min(max(edgeDelta, 1), _maxDelta),
          (i) => DemoGraphDeltaOption.addEdge,
        ),
      );
    }

    if (nodeDelta < _maxDelta && _map.isNotEmpty) {
      // we can remove nodes!
      churnOptions.addAll(
        Iterable.generate(
          min(max(-nodeDelta, 1), _maxDelta),
          (i) => DemoGraphDeltaOption.removeNode,
        ),
      );
    }

    if (_edgeStuff && edgeDelta < _maxDelta && edgeCount > 0) {
      // we can remove edges!
      churnOptions.addAll(
        Iterable.generate(
          min(max(-nodeDelta, 1), _maxDelta),
          (i) => DemoGraphDeltaOption.removeEdge,
        ),
      );
    }

    if (churnOptions.isEmpty) {
      //print('noop for now!');
      return DemoGraphDeltaOption.removeNode;
    }

    assert(churnOptions.isNotEmpty);

    final option = churnOptions[_rnd.nextInt(churnOptions.length)];

    //print('picked $option from $churnOptions');

    switch (option) {
      case DemoGraphDeltaOption.addNode:
        addNode();
      case DemoGraphDeltaOption.removeNode:
        removeNode();
      case DemoGraphDeltaOption.addEdge:
        addEdge();
      case DemoGraphDeltaOption.removeEdge:
        removeEdge();
    }
    return option;
  }

  void addNode() {
    // TODO: we could be more efficient by tracking the nodes we've randomly removed
    var newNode = -1;
    for (var i = 0; i < (_map.length + 1); i++) {
      if (!_map.containsKey(i)) {
        newNode = i;
        break;
      }
    }
    assert(newNode != -1);

    _map[newNode] = _createEmpty();

    //print('added $newNode');
    _notifier.notify();
  }

  void removeNode() {
    if (_map.isEmpty) {
      throw UnsupportedError('Cannot remove a node from an empty map');
    }

    final key = _randomNode();
    _map.remove(key);

    if (_edgeStuff) {
      var removeCount = 0;
      for (var e in _map.values) {
        if (_edgeStuff && e.remove(key)) {
          removeCount++;
        }
      }

      print('removed $key with $removeCount edges');
    }
    _notifier.notify();
  }

  void addEdge() {
    if (_map.isEmpty) {
      throw UnsupportedError('Cannot add an edge to an empty map');
    }
    var count = 0;
    var added = false;
    do {
      count++;
      final a = _randomNode();
      final b = _randomNode();
      added = a != b && !_map[b]!.contains(a) && _map[a]!.add(b);
      if (added) {
        print('Added edge: $a -> $b');
      } else if (count > _maxTries) {
        throw StateError(
          'could not find a place to add an edge after $_maxTries tries',
        );
      }
    } while (!added);
  }

  void removeEdge() {
    if (_map.length < 2) {
      throw UnsupportedError(
        'Cannot remove an edge from an map with 0 or 1 nodes',
      );
    }

    var count = 0;
    var removed = false;
    do {
      count++;
      final a = _randomNode();
      final b = _randomNode();
      removed = a != b && (_map[a]!.remove(b) || _map[b]!.remove(a));
      if (removed) {
        print('removed edge: $a -> $b');
      } else if (count > _maxTries) {
        print('could not an edge to remove after $_maxTries tries');
        return;
      }
    } while (!removed);
  }

  int _randomNode() {
    final index = _rnd.nextInt(_map.length);
    return _map.keys.elementAt(index);
  }

  //
  // GraphData bits
  //
  @override
  Iterable<int> edgesFrom(int node) => _edgeStuff ? _map[node]! : const [];

  @override
  Iterable<int> get nodes => _map.keys;

  @override
  bool hasNode(int node) => _map.containsKey(node);

  //
  // Listenable bits
  //
  @override
  void addListener(VoidCallback listener) => _notifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _notifier.removeListener(listener);
}
