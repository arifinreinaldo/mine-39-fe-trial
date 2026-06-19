import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../models/game_board.dart';
import '../models/terrain.dart';
import '../models/tile.dart';
import '../models/unit.dart';
import '../models/unit_class.dart';
import '../models/weapon.dart';

/// Loads chapter definitions (maps + unit placements) from JSON assets and
/// builds a ready-to-play [GameBoard]. Keeping this out of the models means the
/// model layer stays pure Dart with no Flutter dependency.
class ChapterRepository {
  const ChapterRepository();

  Future<GameBoard> loadChapter(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _boardFromJson(json);
  }

  GameBoard _boardFromJson(Map<String, dynamic> json) {
    final width = json['width'] as int;
    final height = json['height'] as int;
    final name = (json['name'] as String?) ?? 'Chapter';

    final rawTiles = (json['tiles'] as List)
        .map((row) => (row as List).map((c) => c as int).toList())
        .toList();

    final tiles = <List<Tile>>[];
    for (var y = 0; y < height; y++) {
      final row = <Tile>[];
      for (var x = 0; x < width; x++) {
        row.add(Tile(
          position: Point(x, y),
          terrain: TerrainType.fromId(rawTiles[y][x]),
        ));
      }
      tiles.add(row);
    }

    final units = (json['units'] as List)
        .map((u) => _unitFromJson(u as Map<String, dynamic>))
        .toList();

    return GameBoard(
      chapterName: name,
      width: width,
      height: height,
      tiles: tiles,
      units: units,
    );
  }

  Unit _unitFromJson(Map<String, dynamic> json) {
    final unitClass = UnitClass.fromId(json['class'] as String);
    final weaponId = json['weapon'] as String?;
    final weapon = weaponId != null
        ? Weapon.byId(weaponId)
        : Weapon.catalogue.values.firstWhere(
            (w) => w.type == unitClass.defaultWeapon,
            orElse: () => Weapon.byId('ironSword'),
          );

    return Unit(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? json['id'] as String,
      unitClass: unitClass,
      faction: Faction.values.firstWhere(
        (f) => f.name == json['faction'],
        orElse: () => Faction.enemy,
      ),
      maxHp: json['hp'] as int,
      strength: json['strength'] as int,
      magic: json['magic'] as int,
      skill: json['skill'] as int,
      speed: json['speed'] as int,
      luck: json['luck'] as int,
      defense: json['defense'] as int,
      resistance: json['resistance'] as int,
      weapon: weapon,
      x: json['x'] as int,
      y: json['y'] as int,
      level: (json['level'] as int?) ?? 1,
      movement: json['movement'] as int?,
    );
  }
}
