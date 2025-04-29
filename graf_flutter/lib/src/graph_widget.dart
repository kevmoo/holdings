// ignore_for_file: lines_longer_than_80_chars

import 'dart:math'; // Needed for sqrt, pow, Random

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Needed for Ticker and SchedulerBinding
import 'package:graf/graf.dart';

import 'edge_painter.dart';
import 'node_flow_delegate.dart';
import 'node_widget.dart';

// Define in a file like force_directed_graph_view.dart
class ForceDirectedGraphView<T> extends StatefulWidget {
  final GraphData<T> graphData;
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
    this.damping = 0.999,
    this.defaultSpringLength = 10,
    this.maxForce = 1000,
    this.minEnergyThreshold = 0.1, // Stop when avg velocity is low
    this.nodeSize = 60,
    this.repulsionConstant = 19000, // Adjust based on scale
    this.springStiffness = 0.08,
    this.terminalVelocity = 1000,
    this.timeStep = 0.016, // Roughly 1/60 seconds, good starting point
    this.tooFar = 50000, // distance at which we should ignore repulsion
  });

  @override
  State<ForceDirectedGraphView<T>> createState() =>
      _ForceDirectedGraphViewState<T>();
}

// Add TickerProviderStateMixin to manage the Ticker
class _ForceDirectedGraphViewState<T> extends State<ForceDirectedGraphView<T>>
    with TickerProviderStateMixin {
  final GlobalKey _sizeKey = GlobalKey(debugLabel: 'size key');
  static final _random = Random();

  late Ticker _ticker;
  Duration _lastTickTime = Duration.zero;
  final _notifier = ValueNotifier<int>(0);

  // Physics state maps (Node ID -> Value)
  final _nodePositions = <T, Offset>{};
  final _nodeVelocities = <T, Offset>{};
  final _nodeForces = <T, Offset>{}; // Force accumulated this step

  bool _isSettled = false; // Flag to indicate simulation has settled

  // --- initState, dispose, _onTick remain the same ---
  @override
  void initState() {
    super.initState();

    // Initialize positions randomly within a plausible area
    for (var node in widget.graphData.nodes) {
      _nodePositions[node] = Offset(
        _random.nextDouble() * 200 - 100, // e.g., x from 50 to 250
        _random.nextDouble() * 200 - 100, // e.g., y from 50 to 250
      );
      _nodeVelocities[node] = Offset.zero;
      _nodeForces[node] = Offset.zero;
    }

    // Create and start the ticker
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose(); // Stop and dispose the ticker when the widget is removed
    super.dispose();
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
      (elapsed - _lastTickTime).inMicroseconds / 1000000.0,
    );
    _lastTickTime = elapsed;

    /*
    final renderSize =
        (_sizeKey.currentContext!.findRenderObject() as RenderBox).size;

     */

    // --- Physics Simulation Step ---

    // 1. Clear forces
    _nodeForces.updateAll((key, value) => Offset.zero);

    final nodeIds = _nodePositions.keys.toList();
    for (var i = 0; i < nodeIds.length; i++) {
      final nodeId1 = nodeIds[i];
      final pos1 = _nodePositions[nodeId1]!;

      for (var j = i + 1; j < nodeIds.length; j++) {
        final nodeId2 = nodeIds[j];
        final pos2 = _nodePositions[nodeId2]!;

        final delta = pos2 - pos1; // Vector from pos1 to pos2
        final distanceSquared = delta.distanceSquared;
        final distance = sqrt(distanceSquared);

        if (distance < 0.1) {
          // Avoid division by zero or near-zero
          // Add a small random nudge if nodes are on top of each other
          final nudge =
              Offset(_random.nextDouble() - 0.5, _random.nextDouble() - 0.5) *
              widget.nodeSize *
              0.1;
          // Use temporary variables to avoid modifying map during iteration issues potentially
          final newPos1 = pos1 - nudge;
          final newPos2 = pos2 + nudge;
          // Schedule update after loop or handle carefully
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _nodePositions[nodeId1] = newPos1;
                _nodePositions[nodeId2] = newPos2;
              });
            }
          });
          continue; // Skip force calculation if too close
        }

        // Repulsive force: F = C / distance^2
        // Normalize delta safely
        final direction = delta / distance;

        var forceMagnitude = 0.0;

        if (distance < widget.tooFar) {
          final repulsionMagnitude = widget.repulsionConstant / distanceSquared;
          forceMagnitude -= repulsionMagnitude;
        }

        // attractive force!
        if (widget.graphData.hasEdge(nodeId1, nodeId2)) {
          if (distance < 0.1) {
            continue; // Avoid division by zero or near-zero for direction
          }

          // Attractive force (Hooke's Law): F = k * (distance - L0)
          final attractionMagnitude =
              widget.springStiffness * (distance - widget.defaultSpringLength);

          // Normalize delta safely
          forceMagnitude += attractionMagnitude;
        }

        final force = direction * forceMagnitude;
        // Apply forces using temporary variables or directly if safe
        _nodeForces[nodeId1] = _nodeForces[nodeId1]! + force;
        _nodeForces[nodeId2] = _nodeForces[nodeId2]! - force;
      }

      _nodeForces[nodeId1] = _limitMagnitude(
        _nodeForces[nodeId1]!,
        widget.maxForce,
      );
    }

    // 4. Update Velocities and Positions (Euler Integration) - O(N)
    double totalVelocityMagnitudeSquared = 0;
    final nextPositions = <T, Offset>{}; // Store next positions

    _nodePositions.forEach((nodeId, pos) {
      var force = _nodeForces[nodeId]!;

      //
      // Add a tiny force towards the center
      //
      // TODO: make this configurable!
      force -= pos * 0.001;

      var velocity = _nodeVelocities[nodeId]!; // Get current velocity

      // Update velocity: v = v + a * dt
      velocity = velocity + force * dt;

      // Apply damping
      velocity = velocity * widget.damping;

      velocity = _limitMagnitude(velocity, widget.terminalVelocity);

      // Update position: p = p + v * dt
      final newPosition = pos + velocity * dt;

      _nodeVelocities[nodeId] = velocity; // Store updated velocity
      nextPositions[nodeId] = newPosition; // Store next position

      totalVelocityMagnitudeSquared +=
          velocity.distanceSquared; // Sum squared velocities
    });

    // Update all positions at once after calculations
    _nodePositions.addAll(nextPositions);

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
          painter: EdgePainter<T>(widget.graphData, _nodePositions),
          willChange: true,
          // Ensure the painter repaints when positions change
          // isComplex/willChange might be useful if edges are numerous
        ),
      ),

      // 2. Flow for Nodes
      Flow(
        delegate: NodeFlowDelegate<T>(
          repaint: _notifier,
          nodePositions: _nodePositions.values,
          nodeSize: widget.nodeSize,
        ),
        // Provide the NodeWidgets as direct children
        children: _nodePositions.keys
            .map(
              (node) => GestureDetector(
                child: NodeWidget<T>(node: node, size: widget.nodeSize),
                onPanUpdate: (details) {
                  if (mounted) {
                    setState(() {
                      _nodePositions[node] =
                          _nodePositions[node]! + details.delta;
                      // Optionally pause forces on this node while dragging
                      _nodeVelocities[node] = Offset.zero;
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

Offset _limitMagnitude(Offset velocity, double maxMagnitude) {
  if (velocity.distanceSquared > maxMagnitude * maxMagnitude) {
    velocity *= maxMagnitude / velocity.distance;
  }
  return velocity;
}
