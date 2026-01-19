import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A delegate for creating a floating tab header that sticks when scrolling
class FloatingTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  FloatingTabHeaderDelegate({
    required this.child,
    this.minHeight = 82.0,
    this.maxHeight = 82.0,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(FloatingTabHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
