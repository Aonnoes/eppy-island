import 'package:eppy_island/game/screen_fade.dart';
import 'package:eppy_island/game/eppy_island.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  runApp(
    GameWidget<EppyIsland>(
      game: EppyIsland(),
      overlayBuilderMap: {
        ScreenFade.overlayKey: (context, game) => game.fade.build(context),
      },
    ),
  );
}
