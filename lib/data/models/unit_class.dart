import 'unit_trait.dart';
import 'weapon.dart';

export 'unit_trait.dart';

/// Promotion tier. Trainees promote twice (trainee -> trainee2 -> super, or an
/// early branch into a normal base class).
enum ClassTier { trainee, trainee2, base, promoted, superTier }

/// Class-locked skills (effects to be wired up incrementally).
enum ClassSkill { none, greatShield, pierce, silencer, sureShot, slayer, summon, crit15, steal, dance }

/// Per-class stat caps. HP caps at 60 and Luck at 30 for every class, so those
/// carry defaults. The CON cap is derived from traits (mounted/flying 25,
/// foot 20), not stored here.
class StatCaps {
  const StatCaps({
    this.hp = 60,
    this.str = 20,
    this.mag = 20,
    this.skl = 20,
    this.spd = 20,
    this.def = 20,
    this.res = 20,
    this.luck = 30,
  });

  final int hp;
  final int str;
  final int mag;
  final int skl;
  final int spd;
  final int def;
  final int res;
  final int luck;
}

/// Unpromoted classes (including trainees) cap every combat stat at 20.
const StatCaps _cap20 = StatCaps();

/// Flat stat boosts granted on promotion (never Luck).
class StatDelta {
  const StatDelta({
    this.hp = 0,
    this.str = 0,
    this.mag = 0,
    this.skl = 0,
    this.spd = 0,
    this.def = 0,
    this.res = 0,
    this.con = 0,
    this.move = 0,
  });

  final int hp, str, mag, skl, spd, def, res, con, move;
}

/// One branch of a promotion: the target class, the item it consumes, the stat
/// bonus, and any newly-gained weapon type or skill.
class Promotion {
  const Promotion(
    this.to, {
    required this.item,
    this.bonus = const StatDelta(),
    this.gainsWeapon,
    this.gainsSkill,
  });

  final UnitClass to;
  final String item;
  final StatDelta bonus;
  final WeaponType? gainsWeapon;
  final ClassSkill? gainsSkill;
}

/// Every class is fully described by: weapon proficiency ([weapons]), body type
/// ([traits]) + [baseMove], promotion [tier], an optional [skill], and its
/// [caps]. Display names are NOT stored here — they live in the localization
/// layer keyed by `class.<name>`, so they can be swapped per locale.
enum UnitClass {
  // ---- Trainees -------------------------------------------------------------
  journeyman(baseMove: 4, traits: {}, weapons: {WeaponType.axe}, tier: ClassTier.trainee),
  recruit(baseMove: 4, traits: {}, weapons: {WeaponType.lance}, tier: ClassTier.trainee),
  pupil(baseMove: 4, traits: {}, weapons: {WeaponType.magic}, tier: ClassTier.trainee),
  journeyman2(baseMove: 5, traits: {}, weapons: {WeaponType.axe}, tier: ClassTier.trainee2),
  recruit2(baseMove: 5, traits: {}, weapons: {WeaponType.lance}, tier: ClassTier.trainee2),
  pupil2(baseMove: 5, traits: {}, weapons: {WeaponType.magic}, tier: ClassTier.trainee2),

  // ---- Base classes ---------------------------------------------------------
  lord(baseMove: 5, traits: {}, weapons: {WeaponType.sword}, tier: ClassTier.base),
  myrmidon(baseMove: 5, traits: {}, weapons: {WeaponType.sword}, tier: ClassTier.base),
  mercenary(baseMove: 5, traits: {}, weapons: {WeaponType.sword}, tier: ClassTier.base),
  thief(baseMove: 6, traits: {}, weapons: {WeaponType.sword}, tier: ClassTier.base, skill: ClassSkill.steal),
  fighter(baseMove: 5, traits: {}, weapons: {WeaponType.axe}, tier: ClassTier.base),
  pirate(baseMove: 5, traits: {}, weapons: {WeaponType.axe}, tier: ClassTier.base),
  archer(baseMove: 5, traits: {}, weapons: {WeaponType.bow}, tier: ClassTier.base),
  knight(baseMove: 4, traits: {UnitTrait.armored}, weapons: {WeaponType.lance}, tier: ClassTier.base),
  soldier(baseMove: 5, traits: {}, weapons: {WeaponType.lance}, tier: ClassTier.base),
  cavalier(baseMove: 7, traits: {UnitTrait.mounted}, weapons: {WeaponType.sword, WeaponType.lance}, tier: ClassTier.base),
  pegasusKnight(baseMove: 7, traits: {UnitTrait.flying}, weapons: {WeaponType.lance}, tier: ClassTier.base),
  wyvernRider(baseMove: 7, traits: {UnitTrait.flying}, weapons: {WeaponType.lance}, tier: ClassTier.base),
  mage(baseMove: 5, traits: {}, weapons: {WeaponType.magic}, tier: ClassTier.base),
  shaman(baseMove: 5, traits: {}, weapons: {WeaponType.magic}, tier: ClassTier.base),
  monk(baseMove: 5, traits: {}, weapons: {WeaponType.magic}, tier: ClassTier.base),
  priest(baseMove: 5, traits: {}, weapons: {WeaponType.magic}, tier: ClassTier.base),
  cleric(baseMove: 5, traits: {}, weapons: {WeaponType.magic}, tier: ClassTier.base),
  troubadour(baseMove: 6, traits: {UnitTrait.mounted}, weapons: {WeaponType.magic}, tier: ClassTier.base),
  dancer(baseMove: 5, traits: {}, weapons: <WeaponType>{}, tier: ClassTier.base, skill: ClassSkill.dance),

  // ---- Promoted -------------------------------------------------------------
  greatLord(baseMove: 7, traits: {UnitTrait.mounted}, weapons: {WeaponType.sword}, tier: ClassTier.promoted,
      caps: StatCaps(str: 27, skl: 26, spd: 24, def: 23, res: 23)),
  swordmaster(baseMove: 6, traits: {}, weapons: {WeaponType.sword}, tier: ClassTier.promoted, skill: ClassSkill.crit15,
      caps: StatCaps(str: 24, skl: 29, spd: 30, def: 22, res: 23)),
  assassin(baseMove: 6, traits: {}, weapons: {WeaponType.sword}, tier: ClassTier.promoted, skill: ClassSkill.silencer,
      caps: StatCaps(str: 20, skl: 30, spd: 30, def: 20, res: 20)),
  rogue(baseMove: 6, traits: {}, weapons: {WeaponType.sword}, tier: ClassTier.promoted, skill: ClassSkill.steal,
      caps: StatCaps(str: 20, skl: 30, spd: 30, def: 20, res: 20)),
  hero(baseMove: 6, traits: {}, weapons: {WeaponType.sword, WeaponType.axe}, tier: ClassTier.promoted,
      caps: StatCaps(str: 25, skl: 30, spd: 26, def: 25, res: 22)),
  warrior(baseMove: 6, traits: {}, weapons: {WeaponType.axe, WeaponType.bow}, tier: ClassTier.promoted,
      caps: StatCaps(str: 30, skl: 28, spd: 26, def: 26, res: 22)),
  berserker(baseMove: 6, traits: {}, weapons: {WeaponType.axe}, tier: ClassTier.promoted, skill: ClassSkill.crit15,
      caps: StatCaps(str: 30, skl: 29, spd: 28, def: 23, res: 21)),
  ranger(baseMove: 7, traits: {UnitTrait.mounted}, weapons: {WeaponType.sword, WeaponType.bow}, tier: ClassTier.promoted,
      caps: StatCaps(str: 25, skl: 28, spd: 30, def: 24, res: 23)),
  sniper(baseMove: 6, traits: {}, weapons: {WeaponType.bow}, tier: ClassTier.promoted, skill: ClassSkill.sureShot,
      caps: StatCaps(str: 25, skl: 30, spd: 28, def: 25, res: 23)),
  general(baseMove: 5, traits: {UnitTrait.armored}, weapons: {WeaponType.sword, WeaponType.lance, WeaponType.axe}, tier: ClassTier.promoted, skill: ClassSkill.greatShield,
      caps: StatCaps(str: 29, skl: 27, spd: 24, def: 30, res: 25)),
  greatKnight(baseMove: 6, traits: {UnitTrait.mounted, UnitTrait.armored}, weapons: {WeaponType.sword, WeaponType.lance, WeaponType.axe}, tier: ClassTier.promoted,
      caps: StatCaps(str: 28, skl: 24, spd: 24, def: 29, res: 25)),
  paladin(baseMove: 8, traits: {UnitTrait.mounted}, weapons: {WeaponType.sword, WeaponType.lance}, tier: ClassTier.promoted,
      caps: StatCaps(str: 25, skl: 26, spd: 24, def: 25, res: 25)),
  falcoknight(baseMove: 8, traits: {UnitTrait.flying}, weapons: {WeaponType.sword, WeaponType.lance}, tier: ClassTier.promoted,
      caps: StatCaps(str: 23, skl: 25, spd: 28, def: 23, res: 26)),
  wyvernKnight(baseMove: 8, traits: {UnitTrait.flying}, weapons: {WeaponType.lance}, tier: ClassTier.promoted, skill: ClassSkill.pierce,
      caps: StatCaps(str: 25, skl: 26, spd: 28, def: 24, res: 22)),
  wyvernLord(baseMove: 8, traits: {UnitTrait.flying}, weapons: {WeaponType.sword, WeaponType.lance}, tier: ClassTier.promoted,
      caps: StatCaps(str: 27, skl: 25, spd: 23, def: 28, res: 22)),
  sage(baseMove: 6, traits: {}, weapons: {WeaponType.magic}, tier: ClassTier.promoted,
      caps: StatCaps(mag: 28, skl: 30, spd: 26, def: 21, res: 25)),
  mageKnight(baseMove: 7, traits: {UnitTrait.mounted}, weapons: {WeaponType.magic}, tier: ClassTier.promoted,
      caps: StatCaps(mag: 24, skl: 26, spd: 25, def: 24, res: 25)),
  druid(baseMove: 6, traits: {}, weapons: {WeaponType.magic}, tier: ClassTier.promoted,
      caps: StatCaps(mag: 29, skl: 26, spd: 26, def: 21, res: 28)),
  summoner(baseMove: 6, traits: {}, weapons: {WeaponType.magic}, tier: ClassTier.promoted, skill: ClassSkill.summon,
      caps: StatCaps(mag: 27, skl: 27, spd: 26, def: 20, res: 28)),
  bishop(baseMove: 6, traits: {}, weapons: {WeaponType.magic}, tier: ClassTier.promoted, skill: ClassSkill.slayer,
      caps: StatCaps(mag: 25, skl: 26, spd: 24, def: 22, res: 30)),
  valkyrie(baseMove: 7, traits: {UnitTrait.mounted}, weapons: {WeaponType.magic}, tier: ClassTier.promoted,
      caps: StatCaps(mag: 25, skl: 24, spd: 25, def: 24, res: 28)),
  superJourneyman(baseMove: 6, traits: {}, weapons: {WeaponType.axe}, tier: ClassTier.superTier, skill: ClassSkill.crit15,
      caps: StatCaps(str: 26, skl: 29, spd: 28, def: 23, res: 23)),
  superRecruit(baseMove: 6, traits: {}, weapons: {WeaponType.lance}, tier: ClassTier.superTier, skill: ClassSkill.crit15,
      caps: StatCaps(str: 23, skl: 30, spd: 29, def: 22, res: 26)),
  superPupil(baseMove: 6, traits: {}, weapons: {WeaponType.magic}, tier: ClassTier.superTier,
      caps: StatCaps(mag: 29, skl: 28, spd: 27, def: 21, res: 26)),
  necromancer(baseMove: 6, traits: {}, weapons: {WeaponType.magic}, tier: ClassTier.promoted, skill: ClassSkill.summon,
      caps: StatCaps(mag: 30, skl: 25, spd: 25, def: 30, res: 30)),
  mamkute(baseMove: 6, traits: {UnitTrait.flying}, weapons: {WeaponType.magic}, tier: ClassTier.promoted,
      caps: StatCaps(str: 24, skl: 22, spd: 24, def: 24, res: 24));

  const UnitClass({
    required this.baseMove,
    required this.traits,
    required this.weapons,
    required this.tier,
    this.skill = ClassSkill.none,
    this.caps = _cap20,
  });

  final int baseMove;
  final Set<UnitTrait> traits;
  final Set<WeaponType> weapons;
  final ClassTier tier;
  final ClassSkill skill;
  final StatCaps caps;

  bool get isFlier => traits.contains(UnitTrait.flying);
  bool get isMounted => traits.contains(UnitTrait.mounted);
  bool get isArmored => traits.contains(UnitTrait.armored);

  /// CON cap: mounted/flying units carry more (25) than foot units (20).
  int get conCap => (isMounted || isFlier) ? 25 : 20;

  WeaponType get primaryWeapon =>
      weapons.isEmpty ? WeaponType.sword : weapons.first;

  List<Promotion> get promotions => _promotionTree[this] ?? const [];

  static UnitClass fromId(String id) =>
      values.firstWhere((c) => c.name == id, orElse: () => UnitClass.soldier);
}

/// Branching promotion tree. Targets + items are complete; stat bonuses are
/// filled for the representative branches and default to zero elsewhere (the
/// full bonus table can be transcribed in later). Trainee -> base happens at
/// level 10 without an item (`item: 'levelUp'`); base -> promoted consumes the
/// listed item at level >= 10.
final Map<UnitClass, List<Promotion>> _promotionTree = {
  UnitClass.lord: [
    Promotion(UnitClass.greatLord, item: 'lunarBrace', bonus: StatDelta(hp: 4, str: 2, skl: 3, spd: 2, def: 2, res: 5, con: 2, move: 2)),
  ],
  UnitClass.myrmidon: [
    Promotion(UnitClass.swordmaster, item: 'heroCrest', bonus: StatDelta(hp: 5, str: 2, def: 2, res: 1, con: 1, move: 1), gainsSkill: ClassSkill.crit15),
    Promotion(UnitClass.assassin, item: 'heroCrest', bonus: StatDelta(hp: 3, str: 1, def: 2, res: 2, move: 1), gainsSkill: ClassSkill.silencer),
  ],
  UnitClass.mercenary: [
    Promotion(UnitClass.hero, item: 'heroCrest', bonus: StatDelta(hp: 4, str: 1, skl: 2, spd: 2, def: 2, res: 2, con: 2, move: 1), gainsWeapon: WeaponType.axe),
    Promotion(UnitClass.ranger, item: 'heroCrest', bonus: StatDelta(hp: 3, str: 2, skl: 1, spd: 1, def: 3, res: 3, move: 2), gainsWeapon: WeaponType.bow),
  ],
  UnitClass.fighter: [
    Promotion(UnitClass.warrior, item: 'heroCrest', bonus: StatDelta(hp: 3, str: 1, skl: 2, def: 3, res: 3, con: 2, move: 1), gainsWeapon: WeaponType.bow),
    Promotion(UnitClass.hero, item: 'heroCrest', bonus: StatDelta(hp: 4, str: 1, skl: 2, spd: 2, def: 2, res: 2, move: 1), gainsWeapon: WeaponType.sword),
  ],
  UnitClass.thief: [
    Promotion(UnitClass.assassin, item: 'oceanSeal', gainsSkill: ClassSkill.silencer),
    Promotion(UnitClass.rogue, item: 'oceanSeal'),
  ],
  UnitClass.pirate: [
    Promotion(UnitClass.berserker, item: 'oceanSeal', gainsSkill: ClassSkill.crit15),
    Promotion(UnitClass.warrior, item: 'oceanSeal', gainsWeapon: WeaponType.bow),
  ],
  UnitClass.archer: [
    Promotion(UnitClass.sniper, item: 'orionsBolt', gainsSkill: ClassSkill.sureShot),
    Promotion(UnitClass.ranger, item: 'orionsBolt', gainsWeapon: WeaponType.sword),
  ],
  UnitClass.knight: [
    Promotion(UnitClass.general, item: 'knightCrest', bonus: StatDelta(hp: 4, str: 2, skl: 2, spd: 3, def: 2, res: 3, con: 2, move: 1), gainsWeapon: WeaponType.axe, gainsSkill: ClassSkill.greatShield),
    Promotion(UnitClass.greatKnight, item: 'knightCrest', bonus: StatDelta(hp: 3, str: 2, skl: 1, spd: 2, def: 2, res: 1, con: 2, move: 2), gainsWeapon: WeaponType.sword),
  ],
  UnitClass.cavalier: [
    Promotion(UnitClass.paladin, item: 'knightCrest', bonus: StatDelta(hp: 2, str: 1, skl: 1, spd: 1, def: 2, res: 1, con: 2, move: 1)),
    Promotion(UnitClass.greatKnight, item: 'knightCrest', bonus: StatDelta(hp: 3, str: 2, skl: 1, spd: 2, def: 2, con: 4, move: -1), gainsWeapon: WeaponType.axe),
  ],
  UnitClass.pegasusKnight: [
    Promotion(UnitClass.falcoknight, item: 'elysianWhip', gainsWeapon: WeaponType.sword),
    Promotion(UnitClass.wyvernKnight, item: 'elysianWhip', gainsSkill: ClassSkill.pierce),
  ],
  UnitClass.wyvernRider: [
    Promotion(UnitClass.wyvernLord, item: 'elysianWhip', gainsWeapon: WeaponType.sword),
    Promotion(UnitClass.wyvernKnight, item: 'elysianWhip', gainsSkill: ClassSkill.pierce),
  ],
  UnitClass.mage: [
    Promotion(UnitClass.sage, item: 'guidingRing'),
    Promotion(UnitClass.mageKnight, item: 'guidingRing'),
  ],
  UnitClass.shaman: [
    Promotion(UnitClass.druid, item: 'guidingRing'),
    Promotion(UnitClass.summoner, item: 'guidingRing', gainsSkill: ClassSkill.summon),
  ],
  UnitClass.monk: [
    Promotion(UnitClass.bishop, item: 'guidingRing', gainsSkill: ClassSkill.slayer),
    Promotion(UnitClass.sage, item: 'guidingRing'),
  ],
  UnitClass.priest: [
    Promotion(UnitClass.bishop, item: 'guidingRing', gainsSkill: ClassSkill.slayer),
    Promotion(UnitClass.sage, item: 'guidingRing'),
  ],
  UnitClass.cleric: [
    Promotion(UnitClass.bishop, item: 'guidingRing', gainsSkill: ClassSkill.slayer),
    Promotion(UnitClass.valkyrie, item: 'guidingRing'),
  ],
  UnitClass.troubadour: [
    Promotion(UnitClass.valkyrie, item: 'guidingRing'),
    Promotion(UnitClass.mageKnight, item: 'guidingRing'),
  ],
  UnitClass.journeyman: [
    Promotion(UnitClass.fighter, item: 'levelUp'),
    Promotion(UnitClass.pirate, item: 'levelUp'),
    Promotion(UnitClass.journeyman2, item: 'levelUp'),
  ],
  UnitClass.recruit: [
    Promotion(UnitClass.cavalier, item: 'levelUp'),
    Promotion(UnitClass.knight, item: 'levelUp'),
    Promotion(UnitClass.recruit2, item: 'levelUp'),
  ],
  UnitClass.pupil: [
    Promotion(UnitClass.mage, item: 'levelUp'),
    Promotion(UnitClass.shaman, item: 'levelUp'),
    Promotion(UnitClass.pupil2, item: 'levelUp'),
  ],
  UnitClass.journeyman2: [
    Promotion(UnitClass.hero, item: 'heroCrest', gainsWeapon: WeaponType.sword),
    Promotion(UnitClass.superJourneyman, item: 'heroCrest'),
  ],
  UnitClass.recruit2: [
    Promotion(UnitClass.paladin, item: 'knightCrest', gainsWeapon: WeaponType.sword),
    Promotion(UnitClass.superRecruit, item: 'knightCrest'),
  ],
  UnitClass.pupil2: [
    Promotion(UnitClass.mageKnight, item: 'guidingRing'),
    Promotion(UnitClass.superPupil, item: 'guidingRing'),
  ],
};
