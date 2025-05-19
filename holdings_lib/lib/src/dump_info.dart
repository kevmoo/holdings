import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/json_info_codec.dart';

Map<String, dynamic> loadJson(String path) {
  final file = File(path);

  final jsonContent =
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  return jsonContent;
}

Future<AllInfo> load(String path) async {
  final codec = JsonToAllInfoConverter();

  final info = codec.convert(loadJson(path));

  return info;
}
