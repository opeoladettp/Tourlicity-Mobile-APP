import 'package:flutter/material.dart';
import 'notification_icon.dart';
import 'settings_dropdown.dart';

class AppBarActions extends StatelessWidget {
  final bool showNotifications;
  final bool showSettings;
  final List<Widget> additionalActions;

  const AppBarActions({
    super.key,
    this.showNotifications = true,
    this.showSettings = false,
    this.additionalActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...additionalActions,
        if (showNotifications) const NotificationIcon(),
        if (showSettings) const SettingsDropdown(),
      ],
    );
  }
}

// Convenience widgets for common combinations
class NotificationOnlyActions extends StatelessWidget {
  final List<Widget> additionalActions;

  const NotificationOnlyActions({
    super.key,
    this.additionalActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AppBarActions(
      showNotifications: true,
      showSettings: false,
      additionalActions: additionalActions,
    );
  }
}

class SettingsOnlyActions extends StatelessWidget {
  final List<Widget> additionalActions;

  const SettingsOnlyActions({
    super.key,
    this.additionalActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AppBarActions(
      showNotifications: false,
      showSettings: true,
      additionalActions: additionalActions,
    );
  }
}

class BothActions extends StatelessWidget {
  final List<Widget> additionalActions;

  const BothActions({
    super.key,
    this.additionalActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AppBarActions(
      showNotifications: true,
      showSettings: true,
      additionalActions: additionalActions,
    );
  }
}

// Convenience widget for the most common case: notification + settings
class StandardAppBarActions extends StatelessWidget {
  final List<Widget> additionalActions;

  const StandardAppBarActions({
    super.key,
    this.additionalActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...additionalActions,
        const NotificationIcon(),
        const SettingsDropdown(),
      ],
    );
  }
}