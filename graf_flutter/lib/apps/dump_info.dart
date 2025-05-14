import 'package:flutter/material.dart';
import 'package:holdings_lib/holdings_lib.dart' as di;

import '../src/graph_view.dart';
import '../src/graph_widget.dart';

Future<void> main() async {
  final info = await di.load();

  _data = GraphView(
    data: di.DumpInfoGraph(info: info),
    initialVisible: [info.program!.entrypoint],
  );

  runApp(const TimerApp());
}

late final GraphView<di.Info> _data;

class TimerApp extends StatelessWidget {
  const TimerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: ForceDirectedGraphView<di.Info>(
        graphData: _data,
        allowDrag: true,
        nodeWidgetFactory: (info) => InfoWidget(info: info),
        repulsionConstant: 200000,
      ),
    ),
  );
}

class InfoWidget extends StatelessWidget {
  const InfoWidget({super.key, required this.info});

  final di.Info info;

  @override
  Widget build(BuildContext context) => TextButton(
    style: _buttonStyle,
    onPressed: () {
      _data.showEdges(info);
    },
    child: Tooltip(
      child: Text(info.name, textAlign: TextAlign.center),
      message: info.longName,
    ),
  );
}

final _buttonStyle = TextButton.styleFrom(
  backgroundColor: Colors.lightBlueAccent,
);
