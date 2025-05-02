// ignore_for_file: lines_longer_than_80_chars

import 'dart:collection';
import 'dart:math'; // Needed for sqrt, pow, Random

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Needed for Ticker and SchedulerBinding
import 'package:graf/graf.dart';

import 'edge_painter.dart';
import 'node_data.dart';
import 'node_flow_delegate.dart';
import 'utilities.dart';

// Define in a file like force_directed_graph_view.dart
class ForceDirectedGraphView<T> extends StatefulWidget {
  final GraphData<T> graphData;
  final double centerForce;
  final double damping; // Velocity damping factor (0 to 1)
  final double defaultSpringLength; // L0
  final double maxForce;
  final double minEnergyThreshold; // Stop when simulation settles (optional)
  final double nodeSize; // Size to use for node widgets
  final double repulsionConstant; // C
  final double springStiffness; // k in Hooke's Law
  final double terminalVelocity;
  final double timeStep; // dt for simulation (can be fixed or use frame delta)
  final double tooFar; // distance at which we should ignore repulsion

  const ForceDirectedGraphView({
    super.key,
    required this.graphData,
    this.centerForce = 0,
    this.damping = 0.01,
    this.defaultSpringLength = 10,
    this.maxForce = 1000,
    this.minEnergyThreshold = 0.1, // Stop when avg velocity is low
    this.nodeSize = 60,
    this.repulsionConstant = 20000, // Adjust based on scale
    this.springStiffness = 0.05,
    this.terminalVelocity = 1000,
    this.timeStep = 0.016, // Roughly 1/60 seconds, good starting point
    this.tooFar = 50000, // distance at which we should ignore repulsion
  }) : assert(damping >= 0 && damping <= 1, 'damping must be between 0 and 1'),
       assert(repulsionConstant >= 0, 'repulsionConstant must be non-negative'),
       assert(springStiffness >= 0, 'springStiffness must be non-negative');

  @override
  State<ForceDirectedGraphView<T>> createState() =>
      _ForceDirectedGraphViewState<T>();
}

// Add TickerProviderStateMixin to manage the Ticker
class _ForceDirectedGraphViewState<T> extends State<ForceDirectedGraphView<T>>
    with SingleTickerProviderStateMixin {
  final GlobalKey _sizeKey = GlobalKey(debugLabel: 'size key');
  static final _random = Random();

  late Ticker _ticker;
  Duration _lastTickTime = Duration.zero;
  final _notifier = ValueNotifier<int>(0);

  final _nodeData = HashMap<T, NodeData>();
  final _nodeList = <T>[];
  Size _renderSize = const Size(500, 500);

  bool _isSettled = false; // Flag to indicate simulation has settled

  @override
  void initState() {
    super.initState();

    _ensureNodeData();
    // Create and start the ticker
    _ticker = createTicker(_onTick);
    _ticker.start();

    if (widget.graphData is Listenable) {
      (widget.graphData as Listenable).addListener(_onGraphDataChanged);
    }
  }

  @override
  void dispose() {
    _ticker.dispose(); // Stop and dispose the ticker when the widget is removed
    super.dispose();
  }

  void _onGraphDataChanged() {
    if (!_ticker.isActive) {
      _ticker.start();
    }

    _ensureNodeData();
    _isSettled = false;
  }

  void _ensureNodeData() {
    // Initialize positions randomly within a plausible area

    _nodeData.removeWhere((e, _) => !widget.graphData.hasNode(e));

    for (var node in widget.graphData.nodes) {
      _nodeData[node] ??= NodeData(
        position: Offset(
          _random.nextDouble() * _renderSize.width - _renderSize.width / 2,
          _random.nextDouble() * _renderSize.height - _renderSize.height / 2,
        ),
        velocity: Offset.fromDirection(
          _random.nextDouble() * pi * 2,
          20 + _random.nextDouble() * 10,
        ),
      );
    }
  }

  // The callback function for the ticker
  void _onTick(Duration elapsed) {
    if (_isSettled) {
      // Ticker might still be active briefly after settling
      if (_ticker.isActive) {
        _ticker.stop();
      }
      return;
    }

    if (elapsed.inMicroseconds == 0 && _lastTickTime.inMicroseconds == 0) {
      // First tick, use a small fixed step or wait for next tick
      _lastTickTime = elapsed;
      return; // Or use widget.timeStep for the first frame
    }

    // Calculate delta time in seconds, ensure it's positive
    final dt = max(
      widget.timeStep, // Use a minimum timestep
      min(
        (elapsed - _lastTickTime).inMicroseconds / 1000000.0,
        // No more than 3x the timeStep
        widget.timeStep * 3,
      ),
    );
    _lastTickTime = elapsed;

    _renderSize =
        (_sizeKey.currentContext!.findRenderObject() as RenderBox).size;

    // --- Physics Simulation Step ---

    // 1. Clear forces
    for (var e in _nodeData.values) {
      e.force = Offset.zero;
    }

    _nodeList.clear();
    _nodeList.addAll(_nodeData.keys);
    for (var i = 0; i < _nodeList.length; i++) {
      final node1 = _nodeList[i];
      final data1 = _nodeData[node1]!;
      final pos1 = data1.position;
      var force1 = data1.force;

      if (widget.repulsionConstant > 0 || widget.springStiffness > 0) {
        for (var j = i + 1; j < _nodeList.length; j++) {
          final node2 = _nodeList[j];
          final data2 = _nodeData[node2]!;
          final pos2 = data2.position;

          final delta = pos2 - pos1; // Vector from pos1 to pos2
          final distanceSquared = delta.distanceSquared;
          final distance = sqrt(distanceSquared);

          if (distance < 0.01) {
            // TODO: figure out if this should be handled!
            continue; // Skip force calculation if too close
          }

          // Repulsive force: F = C / distance^2
          // Normalize delta safely
          final direction = delta / distance;

          var forceMagnitude = 0.0;

          if (distance < widget.tooFar) {
            final repulsionMagnitude =
                widget.repulsionConstant / distanceSquared;
            forceMagnitude -= repulsionMagnitude;
          }

          // attractive force!
          if (widget.graphData.hasEdge(node1, node2)) {
            if (distance < 0.1) {
              continue; // Avoid division by zero or near-zero for direction
            }

            // Attractive force (Hooke's Law): F = k * (distance - L0)
            final attractionMagnitude =
                widget.springStiffness *
                (distance - widget.defaultSpringLength);

            // Normalize delta safely
            forceMagnitude += attractionMagnitude;
          }

          final pairForce = direction * forceMagnitude;
          // Apply forces using temporary variables or directly if safe
          force1 += pairForce;
          data2.force -= pairForce;
        }
      }

      //
      // Add a tiny force towards the center
      //
      force1 -= pos1 * widget.centerForce;

      //
      // Wall forces
      //
      force1 += wallForce(
        position: pos1,
        size: _renderSize,
        buffer: widget.nodeSize * 2,
        maxForce: 100,
      );

      data1.force = limitMagnitude(force1, widget.maxForce);
    }

    // 4. Update Velocities and Positions (Euler Integration) - O(N)
    double totalVelocityMagnitudeSquared = 0;

    for (var data in _nodeData.values) {
      var velocity = data.velocity; // Get current velocity

      // Update velocity: v = v + a * dt
      velocity = velocity + data.force * dt;

      // Apply damping
      velocity = velocity * (1 - widget.damping);

      velocity = limitMagnitude(velocity, widget.terminalVelocity);

      // Update position: p = p + v * dt
      final newPosition = data.position + velocity * dt;

      data.velocity = velocity; // Store updated velocity
      data.position = newPosition; // Store next position

      totalVelocityMagnitudeSquared +=
          velocity.distanceSquared; // Sum squared velocities
    }

    // 5. Check for Settling (Optional)
    // Calculate average velocity magnitude squared
    final avgVelocityMagnitudeSquared =
        totalVelocityMagnitudeSquared / widget.graphData.nodes.length;

    // Compare squared values to avoid sqrt
    if (avgVelocityMagnitudeSquared <
        (widget.minEnergyThreshold * widget.minEnergyThreshold)) {
      _isSettled = true;
      if (_ticker.isActive) {
        _ticker.stop(); // Stop the ticker
      }
      print(
        'Simulation settled. Average velocity squared: $avgVelocityMagnitudeSquared',
      );
    }

    _notifier.value++;

    // Trigger a repaint to show the updated positions
    // Only call setState if the widget is still mounted
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    key: _sizeKey,
    children: [
      // 1. Edge Painter - draws lines between current node positions
      Positioned.fill(
        child: CustomPaint(
          painter: EdgePainter<T>(widget.graphData, _nodeData),
          willChange: true,
          // Ensure the painter repaints when positions change
          // isComplex/willChange might be useful if edges are numerous
        ),
      ),

      // 2. Flow for Nodes
      Flow(
        delegate: NodeFlowDelegate<T>(
          repaint: _notifier,
          nodePositions: _nodeData.values,
          nodeSize: widget.nodeSize,
        ),
        // Provide the NodeWidgets as direct children
        children: _nodeData.keys
            .map(
              (node) => GestureDetector(
                child: FlutterLogo(size: widget.nodeSize),
                onPanUpdate: (details) {
                  if (mounted) {
                    setState(() {
                      final nodeData = _nodeData[node]!;
                      nodeData.position += details.delta;
                      // Optionally pause forces on this node while dragging
                      nodeData.velocity = Offset.zero;
                      _isSettled = false; // Unsettle if dragged
                      if (!_ticker.isActive) {
                        _ticker.start();
                      }
                    });
                  }
                },
              ),
            )
            .toList(),
      ),
    ],
  );
}
