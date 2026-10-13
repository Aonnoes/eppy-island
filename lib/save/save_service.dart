import 'dart:convert';
import 'dart:io';

import 'package:eppy_island/save/save_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Reads and writes the save file (JSON, in the app's documents folder).
///
/// * No save yet, or an unreadable one: starts from
///   assets/data/default_save.json. A broken save is kept next to the real one
///   as `.corrupt` instead of being thrown away.
/// * Writes go to a temporary file first and are then renamed over the real
///   one, so a crash mid-save can't leave a half-written file.
class SaveService {
  SaveService({this.directory});

  static const String defaultAsset = 'assets/data/default_save.json';
  static const String _fileName = 'eppy_island_save.json';

  /// Where to keep the save. Defaults to the app documents folder.
  final Directory? directory;

  Future<void> _queue = Future<void>.value();

  Future<File> _file() async {
    final dir = directory ?? await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  /// The saved game, or a fresh one from the default save.
  Future<SaveData> load() async {
    try {
      final file = await _file();
      if (await file.exists()) {
        try {
          final json = jsonDecode(await file.readAsString());
          return SaveData.fromJson((json as Map).cast<String, dynamic>());
        } catch (error) {
          debugPrint('Save: could not read ${file.path}: $error');
          await _keepCorrupt(file);
        }
      }
    } catch (error) {
      debugPrint('Save: no access to the save folder: $error');
    }
    return loadDefault();
  }

  Future<SaveData> loadDefault() async {
    final raw = await rootBundle.loadString(defaultAsset);
    return SaveData.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
  }

  /// Writes [data]. Calls are queued, so saves never overlap. Never throws:
  /// a failed save is logged and the game carries on.
  Future<void> save(SaveData data) {
    _queue = _queue.then((_) => _write(data));
    return _queue;
  }

  /// Deletes the save, so the next [load] starts a new game.
  Future<void> reset() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (error) {
      debugPrint('Save: could not delete the save: $error');
    }
  }

  Future<void> _write(SaveData data) async {
    try {
      final file = await _file();
      final temp = File('${file.path}.tmp');
      const encoder = JsonEncoder.withIndent('  ');
      await temp.writeAsString(encoder.convert(data.toJson()), flush: true);
      await temp.rename(file.path);
    } catch (error) {
      debugPrint('Save: failed to write: $error');
    }
  }

  Future<void> _keepCorrupt(File file) async {
    try {
      await file.rename('${file.path}.corrupt');
    } catch (_) {
      // Nothing more to do; the default save is used either way.
    }
  }
}

