import 'dart:collection';

import 'package:dart2js_info/info.dart';
import 'package:graf/graf.dart';

class DumpInfoGraph implements GraphData<Info> {
  DumpInfoGraph({required this.info}) {
    _nodeCache.addAll(info.functions);
    _nodeCache.addAll(info.fields);
  }

  final AllInfo info;

  final _nodeCache = <Info>[];
  final _edgeCache = HashMap<Info, List<Info>>();

  @override
  Iterable<Info> edgesFrom(Info node) =>
      _edgeCache.putIfAbsent(node, () => _edgesFrom(node));

  List<Info> _edgesFrom(Info node) {
    if (node is CodeInfo) {
      return node.uses.map((e) => e.target).toList(growable: false);
    }

    return const [];
  }

  @override
  bool hasNode(Info node) => _nodeCache.contains(node);

  @override
  Iterable<Info> get nodes => _nodeCache;
}
