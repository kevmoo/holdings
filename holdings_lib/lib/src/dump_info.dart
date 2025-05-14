import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/json_info_codec.dart';

Map<String, dynamic> loadJson() {
  final file = File(
    '/Users/kevmoo/github/kevmoo/holdings/holdings_lib/out/info_vote_may_13.json',
  );

  final jsonContent =
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  return jsonContent;
}

Future<AllInfo> load() async {
  final codec = JsonToAllInfoConverter();

  final info = codec.convert(loadJson());

  return info;
}
