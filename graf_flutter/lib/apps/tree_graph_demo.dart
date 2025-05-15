import 'package:flutter/material.dart';
import 'package:graf/example_graphs.dart' as example_graphs;

import '../src/graph_widget.dart';

void main() {
  runApp(const TreeGraphDemoApp());
}

final _data = example_graphs.tree();

class TreeGraphDemoApp extends StatelessWidget {
  const TreeGraphDemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(scaffoldBackgroundColor: Colors.white),
    home: Scaffold(
      body: ForceDirectedGraphView<String>(graphData: _data, allowDrag: true),
    ),
  );
}
