import 'package:flutter/widgets.dart';

/// A full-screen black fade drawn as a Flutter overlay on top of the game.
///
/// Because it is a normal Flutter widget (Flame's "overlay" feature), Flutter
/// does the animating and drawing; it doesn't depend on the game loop.
class ScreenFade {
  /// Key used to register the overlay in `GameWidget.overlayBuilderMap`.
  static const String overlayKey = 'screenFade';

  final ValueNotifier<double> _opacity = ValueNotifier<double>(0);
  Duration _duration = Duration.zero;

  /// Fades to [target] opacity (1 = fully black, 0 = clear) over [duration].
  /// Completes when the fade is done.
  Future<void> fadeTo(double target, {required Duration duration}) async {
    _duration = duration; // Set first: the widget reads it when it rebuilds.
    _opacity.value = target;
    await Future<void>.delayed(duration);
  }

  /// The widget to return from the overlay builder.
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _opacity,
      builder: (context, opacity, _) {
        return IgnorePointer(
          child: AnimatedOpacity(
            opacity: opacity,
            duration: _duration,
            curve: Curves.easeInOut,
            child: const SizedBox.expand(
              child: ColoredBox(color: Color(0xFF000000)),
            ),
          ),
        );
      },
    );
  }
}
