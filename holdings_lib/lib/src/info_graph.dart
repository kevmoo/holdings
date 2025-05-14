import 'dart:collection';

import 'package:dart2js_info/info.dart';
import 'package:graf/graf.dart';

class DumpInfoGraph implements GraphData<Info> {
  DumpInfoGraph({required this.info}) {
    _nodeCache.addAll(info.functions);
    _nodeCache.addAll(info.fields);
  }

  final AllInfo info;

  final _nodeCache = HashSet<Info>.identity();

  @override
  Iterable<Info> edgesFrom(Info node) {
    if (node is CodeInfo) {
      return node.uses.map((e) => e.target);
    }

    return const Iterable.empty();
  }

  @override
  bool hasNode(Info node) => _nodeCache.contains(node);

  @override
  Iterable<Info> get nodes => _nodeCache;
}
