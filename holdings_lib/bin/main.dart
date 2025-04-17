import 'dart:collection';

import 'package:holdings_lib/src/dump_info.dart';
import 'package:holdings_lib/src/neo4j.dart';
import 'package:holdings_lib/src/shared.dart';

const _kinds = {'function', 'field'};

TypedId _parse(String iddKey) {
  final index = iddKey.indexOf('/');
  final value = (
    kind: iddKey.substring(0, index),
    key: iddKey.substring(index + 1),
    orignial: iddKey,
  );

  assert(_kinds.contains(value.kind), value.kind);

  return value;
}

Future<void> main(List<String> args) async {
  final info = loadJson();

  final program = info['program'] as JsonMap;

  final elements = info['elements'] as JsonMap;
  final holdingMap = info['holding'] as JsonMap;

  final neo = NeoClient();

  Future<Info> lookup(TypedId id) async {
    final container = elements[id.kind] as JsonMap;
    return container[id.key] as Info;
  }

  final uploaded = <TypedId>{};
  Future<bool> uploadId(TypedId id) async {
    if (uploaded.add(id)) {
      final info = await lookup(id);
      await neo.uploadInfo(info);
      return true;
    }
    return false;
  }

  final toUpload = ListQueue<({TypedId from, TypedId to})>();

  try {
    final entryPointId = _parse(program['entrypoint'] as String);

    toUpload.add((from: entryPointId, to: entryPointId));

    final watch = Stopwatch()..start();

    void log() {
      print('''
------------
Uploaded:       ${uploaded.length}
Uploaded edges: ${neo.edgeCount}
To upload:      ${toUpload.length}''');
    }

    while (toUpload.isNotEmpty) {
      if (watch.elapsed > const Duration(seconds: 1)) {
        watch.reset();
        log();
      }
      final first = toUpload.removeFirst();

      final target = first.to;
      final newItem = await uploadId(target);

      if (first.from != first.to) // ignoring just the first entrypoint!
      {
        await neo.uploadEdge(first.from, first.to, 'holding');
      }

      if (newItem) {
        final holding = holdingMap[target.orignial] as List?;
        if (holding != null) {
          for (final iddKey in holding) {
            final holdingValue = iddKey as JsonMap;
            final id = _parse(holdingValue['id'] as String);
            toUpload.add((from: target, to: id));
          }
        }
      }
    }

    log();
  } finally {
    neo.close();
  }
}
