import 'package:flutter/painting.dart';

class NodeData {
  Offset position;
  Offset velocity;
  Offset force;

  NodeData({
    this.position = Offset.zero,
    this.velocity = Offset.zero,
    this.force = Offset.zero,
  });
}
