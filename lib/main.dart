import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:eppy_island/eppy_island.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  EppyIsland game = EppyIsland();
  runApp(GameWidget(game: kDebugMode ? EppyIsland() : game));
}
