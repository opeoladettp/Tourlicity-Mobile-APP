import 'package:flutter/material.dart';

/// A widget that provides safe bottom padding to prevent content from being
/// hidden under the Android navigation bar or iOS home indicator.
class SafeBottomPadding extends StatelessWidget {
  final Widget child;
  final double? minPadding;
  final bool includeViewInsets;

  const SafeBottomPadding({
    super.key,
    required this.child,
    this.minPadding,
    this.includeViewInsets = true,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final viewInsets = includeViewInsets ? mediaQuery.viewInsets.bottom : 0.0;
    
    // Use the larger of system padding or minimum padding
    final effectivePadding = (minPadding ?? 16.0) + bottomPadding + viewInsets;
    
    return Padding(
      padding: EdgeInsets.only(bottom: effectivePadding),
      child: child,
    );
  }
}

/// A wrapper for SingleChildScrollView that includes safe bottom padding
class SafeScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final bool reverse;
  final Axis scrollDirection;
  final double? minBottomPadding;

  const SafeScrollView({
    super.key,
    required this.child,
    this.padding,
    this.physics,
    this.controller,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.minBottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final effectiveBottomPadding = (minBottomPadding ?? 16.0) + bottomPadding;
    
    EdgeInsetsGeometry effectivePadding;
    if (padding != null) {
      // Add bottom padding to existing padding
      final existingPadding = padding!.resolve(Directionality.of(context));
      effectivePadding = EdgeInsets.fromLTRB(
        existingPadding.left,
        existingPadding.top,
        existingPadding.right,
        existingPadding.bottom + effectiveBottomPadding,
      );
    } else {
      effectivePadding = EdgeInsets.only(bottom: effectiveBottomPadding);
    }

    return SingleChildScrollView(
      padding: effectivePadding,
      physics: physics,
      controller: controller,
      reverse: reverse,
      scrollDirection: scrollDirection,
      child: child,
    );
  }
}

/// A wrapper for Column layouts that includes safe bottom padding
class SafeColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final EdgeInsetsGeometry? padding;
  final double? minBottomPadding;

  const SafeColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.padding,
    this.minBottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final effectiveBottomPadding = (minBottomPadding ?? 16.0) + bottomPadding;
    
    Widget column = Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        ...children,
        SizedBox(height: effectiveBottomPadding),
      ],
    );

    if (padding != null) {
      column = Padding(
        padding: padding!,
        child: column,
      );
    }

    return column;
  }
}

/// A wrapper for ListView that includes safe bottom padding
class SafeListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final bool shrinkWrap;
  final bool reverse;
  final Axis scrollDirection;
  final double? minBottomPadding;

  const SafeListView({
    super.key,
    required this.children,
    this.padding,
    this.physics,
    this.controller,
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.minBottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final effectiveBottomPadding = (minBottomPadding ?? 16.0) + bottomPadding;
    
    EdgeInsetsGeometry effectivePadding;
    if (padding != null) {
      // Add bottom padding to existing padding
      final existingPadding = padding!.resolve(Directionality.of(context));
      effectivePadding = EdgeInsets.fromLTRB(
        existingPadding.left,
        existingPadding.top,
        existingPadding.right,
        existingPadding.bottom + effectiveBottomPadding,
      );
    } else {
      effectivePadding = EdgeInsets.only(bottom: effectiveBottomPadding);
    }

    return ListView(
      padding: effectivePadding,
      physics: physics,
      controller: controller,
      shrinkWrap: shrinkWrap,
      reverse: reverse,
      scrollDirection: scrollDirection,
      children: children,
    );
  }
}