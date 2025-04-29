import 'package:flutter/material.dart';
import 'package:graf/graf.dart';

import 'graf_flutter.dart';

void main() {
  runApp(const MyApp());
}

final _data = GraphData.randomRing(count: 63);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(scaffoldBackgroundColor: Colors.white),
    home: Scaffold(body: ForceDirectedGraphView<String>(graphData: _data)),
  );
}
