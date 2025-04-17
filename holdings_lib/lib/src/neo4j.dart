import 'dart:convert';
import 'dart:io';

import 'shared.dart';

final _host = Uri.parse('http://localhost:7474/');

extension type Info(Map<String, dynamic> map) {
  String get id => map['id'] as String;
  String get name => map['name'] as String;
  String get kind => map['kind'] as String;
  int get size => map['size'] as int;
}

extension type Func(Map<String, dynamic> map) implements Info {}

class NeoClient {
  final _client = HttpClient();

  final _dumpIdToElementId = <String, String>{};

  int _edgeCount = 0;
  int get edgeCount => _edgeCount;

  NeoClient() {
    _client.addCredentials(
      _host,
      '???',
      HttpClientBasicCredentials('neo4j', 'dump_info_12345'),
    );
  }

  Future<String> uploadInfo(Info info) async {
    final results = await _query({
      'statements': [
        {
          'statement':
              'MERGE '
              '(n:info:${info.kind} {id: \$id, name: \$name, size: \$size})'
              ' RETURN n',
          'parameters': info,
        },
      ],
    });

    final result = results.single as JsonMap;
    final data = result['data'] as List;

    final oneData = data.single as JsonMap;

    final metaItem = (oneData['meta'] as List).single as JsonMap;

    final elementId = metaItem['elementId'] as String;

    _dumpIdToElementId[info.id] = elementId;

    return elementId;
  }

  Future<void> uploadEdge(TypedId from, TypedId to, String kind) async {
    _edgeCount++;

    await _query({
      'statements': [
        {
          'statement': '''
MATCH (startNode)
WHERE elementId(startNode) = \$from
MATCH (endNode)
WHERE elementId(endNode) = \$to
MERGE (startNode)-[:$kind]->(endNode)''',
          'parameters': {
            'from': _dumpIdToElementId[from.orignial]!,
            'to': _dumpIdToElementId[to.orignial]!,
          },
        },
      ],
    });
  }

  Future<List> _query(Object? queryBody) async {
    final request = await _client.postUrl(
      Uri.parse('http://localhost:7474/db/neo4j/tx/commit'),
    );
    request.headers.contentType = ContentType.json;
    request.writeln(jsonEncode(queryBody));

    final response = await request.close();

    final body =
        (await response.transform(utf8.decoder).transform(json.decoder).single)
            as JsonMap;

    if (response.statusCode != 200) {
      throw Exception([response.statusCode, response.headers, body].join('\n'));
    }

    final errors = body['errors'] as List;

    if (errors.isNotEmpty) {
      throw StateError(prettyEncode(errors));
    }

    return body['results'] as List;
  }

  void close() {
    _client.close();
  }
}
