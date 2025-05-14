import 'package:dart2js_info/info.dart';
// ignore: implementation_imports
import 'package:dart2js_info/src/util.dart' as u;

export 'package:dart2js_info/info.dart';

export 'src/dump_info.dart';
export 'src/info_graph.dart';

extension InfoExt on Info {
  String get longName => u.longName(this, useLibraryUri: true);
}
