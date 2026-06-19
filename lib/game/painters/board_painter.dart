import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/models/game_board.dart';
import '../../data/models/terrain.dart';
import '../../data/models/unit.dart';

/// A transient damage / miss number rising above a tile. [t] runs 0 -> 1.
class FloatingLabel {
  const FloatingLabel({
    required this.tile,
    required this.text,
    required this.color,
    required this.t,
  });
  final Point<int> tile;
  final String text;
  final Color color;
  final double t;
}

/// Renders the entire battlefield: terrain, range highlights, units, HP bars,
/// and the floating combat number. All animation is fed in via [pixelOverrides]
/// (per-unit pixel position during moves/lunges), [displayHp] (HP shown mid
/// combat) and [floating].
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.board,
    required this.cellSize,
    required this.movementTiles,
    required this.attackTiles,
    required this.activeUnit,
    required this.targets,
    required this.pixelOverrides,
    required this.displayHp,
    required this.floating,
    super.repaint,
  });

  final GameBoard board;
  final double cellSize;
  final Set<Point<int>> movementTiles;
  final Set<Point<int>> attackTiles;
  final Unit? activeUnit;
  final List<Unit> targets;
  final Map<String, Offset> pixelOverrides;
  final Map<String, int> displayHp;
  final FloatingLabel? floating;

  static const _factionColors = {
    Faction.player: Color(0xFF4F7FE0),
    Faction.enemy: Color(0xFFD24B4B),
    Faction.npc: Color(0xFF53B36B),
  };

  static const _classCode = {
    'Lord': 'Lo',
    'Myrmidon': 'My',
    'Knight': 'Kn',
    'Soldier': 'So',
    'Fighter': 'Fi',
    'Archer': 'Ar',
    'Mage': 'Ma',
  };

  @override
  void paint(Canvas canvas, Size size) {
    _paintTerrain(canvas);
    _paintHighlights(canvas);
    _paintGrid(canvas);
    _paintTargets(canvas);
    _paintUnits(canvas);
    _paintFloating(canvas);
  }

  void _paintTerrain(Canvas canvas) {
    for (var y = 0; y < board.height; y++) {
      for (var x = 0; x < board.width; x++) {
        final terrain = board.tiles[y][x].terrain;
        final rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);
        canvas.drawRect(rect, Paint()..color = _terrainColor(terrain));
      }
    }
  }

  void _paintHighlights(Canvas canvas) {
    final movePaint = Paint()..color = const Color(0x554F7FE0);
    final attackPaint = Paint()..color = const Color(0x55D24B4B);
    for (final p in attackTiles) {
      canvas.drawRect(_cellRect(p), attackPaint);
    }
    for (final p in movementTiles) {
      canvas.drawRect(_cellRect(p), movePaint);
    }
  }

  void _paintGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var x = 0; x <= board.width; x++) {
      canvas.drawLine(Offset(x * cellSize, 0),
          Offset(x * cellSize, board.height * cellSize), paint);
    }
    for (var y = 0; y <= board.height; y++) {
      canvas.drawLine(Offset(0, y * cellSize),
          Offset(board.width * cellSize, y * cellSize), paint);
    }
  }

  void _paintTargets(Canvas canvas) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFFC107);
    for (final t in targets) {
      canvas.drawCircle(
          _cellRect(t.position).center, cellSize * 0.42, ring);
    }
  }

  void _paintUnits(Canvas canvas) {
    final inset = cellSize * 0.12;
    for (final unit in board.units) {
      if (!unit.isAlive) continue;

      final topLeft = pixelOverrides[unit.id] ??
          Offset(unit.x * cellSize, unit.y * cellSize);
      final rect = Rect.fromLTWH(topLeft.dx + inset, topLeft.dy + inset,
          cellSize - 2 * inset, cellSize - 2 * inset);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

      // Active-unit halo.
      if (identical(unit, activeUnit)) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect.inflate(3), const Radius.circular(8)),
            Paint()..color = const Color(0xFFFFE082));
      }

      canvas.drawRRect(rrect, Paint()..color = _factionColors[unit.faction]!);
      canvas.drawRRect(
          rrect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.black.withValues(alpha: 0.4));

      _drawText(
        canvas,
        _classCode[unit.unitClass.label] ?? '??',
        rect.center.translate(0, -cellSize * 0.04),
        color: Colors.white,
        size: cellSize * 0.28,
      );

      _drawHpBar(canvas, rect, unit);

      if (unit.hasActed) {
        canvas.drawRRect(
            rrect, Paint()..color = Colors.black.withValues(alpha: 0.45));
      }
    }
  }

  void _drawHpBar(Canvas canvas, Rect rect, Unit unit) {
    final hp = displayHp[unit.id] ?? unit.hp;
    final frac = unit.maxHp == 0 ? 0.0 : (hp / unit.maxHp).clamp(0.0, 1.0);
    final barRect = Rect.fromLTWH(
        rect.left, rect.bottom - cellSize * 0.12, rect.width, cellSize * 0.09);
    canvas.drawRect(barRect, Paint()..color = Colors.black.withValues(alpha: 0.55));
    canvas.drawRect(
      Rect.fromLTWH(barRect.left, barRect.top, barRect.width * frac, barRect.height),
      Paint()..color = _hpColor(frac),
    );
  }

  void _paintFloating(Canvas canvas) {
    final f = floating;
    if (f == null) return;
    final center = _cellRect(f.tile).center;
    final pos = center.translate(0, -f.t * cellSize * 0.9);
    final alpha = (1.0 - f.t).clamp(0.0, 1.0);
    _drawText(
      canvas,
      f.text,
      pos,
      color: f.color.withValues(alpha: alpha),
      size: cellSize * 0.34,
      weight: FontWeight.w800,
      shadow: true,
    );
  }

  Rect _cellRect(Point<int> p) =>
      Rect.fromLTWH(p.x * cellSize, p.y * cellSize, cellSize, cellSize);

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required Color color,
    required double size,
    FontWeight weight = FontWeight.w600,
    bool shadow = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          shadows: shadow
              ? const [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  Color _terrainColor(TerrainType terrain) => switch (terrain) {
        TerrainType.plain => const Color(0xFF6B8E4E),
        TerrainType.forest => const Color(0xFF3E6B3A),
        TerrainType.mountain => const Color(0xFF8A7A66),
        TerrainType.fort => const Color(0xFF7A7F8A),
        TerrainType.water => const Color(0xFF3E6BA8),
        TerrainType.wall => const Color(0xFF2B2B33),
      };

  Color _hpColor(double frac) {
    if (frac > 0.5) return const Color(0xFF5FD068);
    if (frac > 0.25) return const Color(0xFFE0B23E);
    return const Color(0xFFD24B4B);
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) => true;
}
