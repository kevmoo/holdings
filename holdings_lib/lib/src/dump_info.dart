import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/json_info_codec.dart';

Map<String, dynamic> loadJson() {
  final file = File(
    'out/003_fb8c9a3c3f_segment_button_null/main.dart.js.info.json',
  );

  final jsonContent =
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  return jsonContent;
}

Future<AllInfo> load() async {
  final codec = JsonToAllInfoConverter();

  // final holdings = jsonContent['holding'] ;

  final info = codec.convert(loadJson());

  print(info.version);
  return info;
}
