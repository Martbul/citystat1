import 'package:flutter/material.dart';
import 'package:citystat1/src/widgets/background.dart';

/// A page route that always builds the same screen widget.
///
/// This is useful to inspect new screens being pushed to the Navigator in tests.
abstract class ScreenRoute<T extends Object?> extends PageRoute<T> {
  /// The widget that this page route always builds.
  Widget get screen;
}

/// A [MaterialPageRoute] that always builds the same screen widget.
///
/// This route wraps the [screen] with a [FullScreenBackground] to ensure that the background
/// is always filled with the configured app's background color or image.
class MaterialScreenRoute<T extends Object?> extends MaterialPageRoute<T>
    implements ScreenRoute<T> {
  MaterialScreenRoute({
    required this.screen,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
  }) : super(builder: (_) => FullScreenBackground(child: screen));

  @override
  final Widget screen;
}

/// Builds a new route for the [screen] based on the platform.
///
/// This route wraps the [screen] with a [FullScreenBackground] to ensure that the background
/// is always filled with the configured app's background color or image.
///
/// It will return a [MaterialScreenRoute] on Android and a [CupertinoScreenRoute] on iOS.
Route<T> buildScreenRoute<T>(
  BuildContext context, {
  required Widget screen,
  bool fullscreenDialog = false,
  RouteSettings? settings,
}) {
  return MaterialScreenRoute<T>(
    screen: screen,
    fullscreenDialog: fullscreenDialog,
    settings: settings,
  );
}
