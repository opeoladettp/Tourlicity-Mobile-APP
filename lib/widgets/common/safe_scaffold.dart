import 'package:flutter/material.dart';

/// A wrapper around Scaffold that ensures content is properly positioned
/// above system navigation bars and other system UI elements
class SafeScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final EdgeInsetsGeometry? bodyPadding;

  const SafeScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.drawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.bodyPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: bodyPadding ?? EdgeInsets.only(
            bottom: floatingActionButton != null ? 80 : 16,
          ),
          child: body,
        ),
      ),
    );
  }
}

/// Extension to add safe area padding to any widget
extension SafeAreaExtension on Widget {
  Widget withSafeArea({
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
    EdgeInsetsGeometry? padding,
  }) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: padding != null 
          ? Padding(padding: padding, child: this)
          : this,
    );
  }

  Widget withBottomPadding(BuildContext context, {double extra = 0}) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + extra,
      ),
      child: this,
    );
  }
}