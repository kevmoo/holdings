import 'package:flutter/material.dart';

import 'graf_flutter.dart';
import 'src/demo_graph.dart';

void main() {
  runApp(const MyApp());
}

final _data = DemoGraph();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(scaffoldBackgroundColor: Colors.white),
    home: Scaffold(
      body: Column(
        children: [
          Expanded(child: ForceDirectedGraphView<int>(graphData: _data)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: _data.churn,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(onPressed: _data.addNode, icon: const Icon(Icons.add)),
              IconButton(
                onPressed: _data.removeNode,
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                onPressed: () {
                  //_data.addEdge();
                },
                icon: const Icon(Icons.link),
              ),
              IconButton(
                onPressed: () {
                  //_data.removeEdge();
                },
                icon: const Icon(Icons.link_off),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
