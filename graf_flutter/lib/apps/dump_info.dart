import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:graf/graf.dart';
import 'package:holdings_lib/holdings_lib.dart' as di;
// ignore: implementation_imports
import 'package:holdings_lib/src/sample_files.dart';

import '../src/graph_view.dart';
import '../src/graph_widget.dart';

final _expando = Expando<List<di.Info>>('predecessors');

List<di.Info> _cachingPredecessorFunc(GraphData<di.Info> graph, di.Info node) =>
    _expando[node] ??= graph.getPredecessors(node);

Future<void> main() async {
  final info = await di.load(counterInfo);

  final graph = di.DumpInfoGraph(info: info);

  final dominatorFinder = DominatorFinder.compute(
    graph,
    info.program!.entrypoint,
    predecessorsFunction: _cachingPredecessorFunc,
  );

  final immediateFun = HashMap<di.Info, HashSet<di.Info>>.identity();

  for (var node in graph.nodes) {
    final immediate = dominatorFinder.getImmediateDominator(node);

    if (immediate == null) {
      continue;
    }

    immediateFun.putIfAbsent(immediate, HashSet.new).add(node);
  }

  final toStringBits = {
    for (var entry in immediateFun.entries)
      MapEntry(entry.key, entry.value.toList(growable: false)): entry.value
          .fold(0, (size, info) => size + info.size),
  };

  final sortedEntries = toStringBits.entries.toList()
    ..sort((a, b) => -a.value.compareTo(b.value));

  final biggest = sortedEntries.first;

  final data = GraphView<di.Info>(
    data: graph,
    initialVisible: [biggest.key.key, ...biggest.key.value],
  );

  runApp(_DumpInfoApp(data));
}

class _DumpInfoApp extends StatefulWidget {
  const _DumpInfoApp(this._data);

  final GraphView<di.Info> _data;

  @override
  State<StatefulWidget> createState() => _DumpInfoAppState();
}

class _DumpInfoAppState extends State<_DumpInfoApp> {
  final _selected = HashSet<di.Info>.identity();

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: NotificationListener<_NodeSelectionToggleNotification>(
        child: _NodeModel(
          child: ForceDirectedGraphView<di.Info>(
            graphData: widget._data,
            allowDrag: true,
            nodeWidgetFactory: (info) => InfoWidget(info: info),
            repulsionConstant: 200000,
          ),
          selected: HashSet.identity()..addAll(_selected),
        ),
        onNotification: _selectToggle,
      ),
    ),
  );

  bool _selectToggle(_NodeSelectionToggleNotification toggle) {
    setState(() {
      if (_selected.contains(toggle.info)) {
        _selected.remove(toggle.info);
      } else {
        _selected.add(toggle.info);
      }
    });
    return true;
  }
}

class InfoWidget extends StatelessWidget {
  const InfoWidget({super.key, required this.info});

  final di.Info info;

  @override
  Widget build(BuildContext context) {
    final state = _NodeModel.nodeState(context, info)!;

    return TextButton(
      style: _buttonStyle,
      onPressed: () => _NodeSelectionToggleNotification(info).dispatch(context),
      child: Tooltip(
        child: Text(
          info.name,
          textAlign: TextAlign.center,
          style: state.selected ? _boldStyle : null,
        ),
        message: info.longName,
      ),
    );
  }
}

const _boldStyle = TextStyle(fontWeight: FontWeight.bold);

final _buttonStyle = TextButton.styleFrom(
  backgroundColor: Colors.lightBlueAccent,
);

class _NodeModel extends InheritedModel<di.Info> {
  const _NodeModel({required super.child, required this.selected});

  final HashSet<di.Info> selected;

  static _NodeState? nodeState(BuildContext context, di.Info node) {
    final model = InheritedModel.inheritFrom<_NodeModel>(context, aspect: node);

    if (model == null) {
      return null;
    }

    return _NodeState(selected: model.selected.contains(node), info: node);
  }

  @override
  bool updateShouldNotify(covariant _NodeModel oldWidget) =>
      !(selected.length == oldWidget.selected.length &&
          selected.containsAll(oldWidget.selected));

  @override
  bool updateShouldNotifyDependent(
    covariant _NodeModel oldWidget,
    Set<di.Info> dependencies,
  ) => !dependencies.every(
    (d) => selected.contains(d) == oldWidget.selected.contains(d),
  );
}

class _NodeState {
  _NodeState({required this.selected, required this.info});

  final bool selected;
  final di.Info info;
}

class _NodeSelectionToggleNotification extends Notification {
  const _NodeSelectionToggleNotification(this.info);
  final di.Info info;
}
