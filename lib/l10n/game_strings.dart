import '../data/models/unit_class.dart';
import '../data/models/weapon.dart';

/// Lightweight, swappable localization.
///
/// Nothing visible is hard-coded on the models — every display name is looked
/// up here by a stable key (`class.<id>`, `trait.<id>`, `weaponType.<id>`). To
/// localize, add another map and point [current] at it; to re-skin the world
/// (different class names entirely) just edit the values. A full app would back
/// this with ARB/intl, but the contract (stable id -> display string) is the
/// same.
class GameStrings {
  const GameStrings({required this.localeCode, required Map<String, String> values})
      : _values = values;

  final String localeCode;
  final Map<String, String> _values;

  String t(String key) => _values[key] ?? key;

  String className(UnitClass c) => t('class.${c.name}');
  String traitLabel(UnitTrait tr) => t('trait.${tr.name}');
  String weaponTypeLabel(WeaponType w) => t('weaponType.${w.name}');
  String itemLabel(String id) => t('item.$id');
  String ui(String key) => t('ui.$key');
  String skillLabel(ClassSkill s) =>
      s == ClassSkill.none ? '' : t('skill.${s.name}');

  /// The active locale. Swap this (and trigger a rebuild) to relabel everything.
  static GameStrings current = indonesian;

  static const GameStrings indonesian =
      GameStrings(localeCode: 'id', values: _id);
  static const GameStrings english = GameStrings(localeCode: 'en', values: _en);

  static const List<GameStrings> all = [indonesian, english];
}

/// Indonesian — the default. A "colossal"/wayang-flavoured naming arc: humble
/// trainees, solid base classes, grand promotions.
const Map<String, String> _id = {
  // Trainees
  'class.journeyman': 'Perantau',
  'class.recruit': 'Taruna',
  'class.pupil': 'Pemuda Desa',
  'class.journeyman2': 'Perantau Tangguh',
  'class.recruit2': 'Taruna Madya',
  'class.pupil2': 'Pemuda Tangguh',
  // Base
  'class.lord': 'Bangsawan',
  'class.myrmidon': 'Pesilat',
  'class.mercenary': 'Tentara Bayaran',
  'class.thief': 'Pencuri',
  'class.fighter': 'Petarung',
  'class.pirate': 'Bajak Laut',
  'class.archer': 'Pemanah',
  'class.knight': 'Ksatria Baja',
  'class.soldier': 'Prajurit',
  'class.cavalier': 'Prajurit Berkuda',
  'class.pegasusKnight': 'Penunggang Sembrani',
  'class.wyvernRider': 'Penunggang Naga',
  'class.mage': 'Penyihir',
  'class.shaman': 'Dukun',
  'class.monk': 'Biksu',
  'class.priest': 'Pendeta',
  'class.cleric': 'Tabib',
  'class.troubadour': 'Tabib Berkuda',
  'class.dancer': 'Penari',
  // Promoted
  'class.greatLord': 'Maharaja',
  'class.swordmaster': 'Pendekar',
  'class.assassin': 'Pembunuh Senyap',
  'class.rogue': 'Pencuri Ulung',
  'class.hero': 'Pahlawan',
  'class.warrior': 'Prajurit Perang',
  'class.berserker': 'Pengamuk',
  'class.ranger': 'Pemburu Berkuda',
  'class.sniper': 'Pemanah Jitu',
  'class.general': 'Senapati',
  'class.greatKnight': 'Ksatria Agung',
  'class.paladin': 'Satria Berkuda',
  'class.falcoknight': 'Satria Sembrani',
  'class.wyvernKnight': 'Ksatria Naga',
  'class.wyvernLord': 'Panglima Naga',
  'class.sage': 'Begawan',
  'class.mageKnight': 'Penyihir Berkuda',
  'class.druid': 'Pawang',
  'class.summoner': 'Pemanggil Arwah',
  'class.bishop': 'Pendeta Agung',
  'class.valkyrie': 'Bidadari Perang',
  'class.superJourneyman': 'Petarung Sakti',
  'class.superRecruit': 'Prajurit Sakti',
  'class.superPupil': 'Penyihir Sakti',
  'class.necromancer': 'Dukun Maut',
  'class.mamkute': 'Penjelma Naga',
  // Traits
  'trait.mounted': 'Berkuda',
  'trait.armored': 'Berzirah',
  'trait.flying': 'Terbang',
  // Weapon types
  'weaponType.sword': 'Pedang',
  'weaponType.lance': 'Tombak',
  'weaponType.axe': 'Kapak',
  'weaponType.bow': 'Panah',
  'weaponType.magic': 'Sihir',
  // Promotion items
  'item.heroCrest': 'Lambang Pahlawan',
  'item.knightCrest': 'Lambang Ksatria',
  'item.guidingRing': 'Cincin Pemandu',
  'item.orionsBolt': 'Panah Orion',
  'item.oceanSeal': 'Segel Samudra',
  'item.elysianWhip': 'Cambuk Elysia',
  'item.lunarBrace': 'Gelang Bulan',
  'item.solarBrace': 'Gelang Surya',
  'item.levelUp': 'Tingkat 10',
  // Skills
  'skill.greatShield': 'Perisai Agung',
  'skill.pierce': 'Tembus',
  'skill.silencer': 'Pukulan Maut',
  'skill.sureShot': 'Bidikan Jitu',
  'skill.slayer': 'Pembasmi',
  'skill.summon': 'Pemanggilan',
  'skill.crit15': 'Naluri Pembunuh',
  'skill.steal': 'Mencuri',
  'skill.dance': 'Tarian',
  // UI
  'ui.attack': 'Serang',
  'ui.wait': 'Tunggu',
  'ui.cancel': 'Batal',
  'ui.promote': 'Naik Kelas',
  'ui.choosePromotion': 'Pilih kelas baru',
  'ui.skill': 'Jurus',
  'ui.subtitle': 'RPG taktik berbasis giliran',
  'ui.startCampaign': 'Mulai Kampanye',
  'ui.turn': 'Giliran',
  'ui.objective': 'Kalahkan semua musuh',
  'ui.playerPhase': 'Fase Pemain',
  'ui.enemyPhase': 'Fase Musuh',
  'ui.endTurn': 'Akhiri Giliran',
  'ui.victory': 'Kemenangan!',
  'ui.defeat': 'Kekalahan',
  'ui.playAgain': 'Main Lagi',
  'ui.nextChapter': 'Bab Berikutnya',
  'ui.campaignComplete': 'Kampanye Selesai!',
  'ui.toTitle': 'Ke Judul',
  'ui.tapUnitHint': 'Ketuk unit biru milikmu untuk bertindak',
  'ui.selectTargetHint': 'Ketuk musuh yang disorot untuk menyerang',
  'ui.heal': 'Sembuhkan',
  'ui.item': 'Ramuan',
  'ui.selectHealHint': 'Ketuk sekutu yang terluka',
  'ui.back': 'Kembali',
};

/// English fallback (generic genre terms).
const Map<String, String> _en = {
  'class.journeyman': 'Journeyman',
  'class.recruit': 'Recruit',
  'class.pupil': 'Apprentice',
  'class.journeyman2': 'Journeyman+',
  'class.recruit2': 'Recruit+',
  'class.pupil2': 'Apprentice+',
  'class.lord': 'Lord',
  'class.myrmidon': 'Myrmidon',
  'class.mercenary': 'Mercenary',
  'class.thief': 'Thief',
  'class.fighter': 'Fighter',
  'class.pirate': 'Pirate',
  'class.archer': 'Archer',
  'class.knight': 'Knight',
  'class.soldier': 'Soldier',
  'class.cavalier': 'Cavalier',
  'class.pegasusKnight': 'Pegasus Knight',
  'class.wyvernRider': 'Wyvern Rider',
  'class.mage': 'Mage',
  'class.shaman': 'Shaman',
  'class.monk': 'Monk',
  'class.priest': 'Priest',
  'class.cleric': 'Cleric',
  'class.troubadour': 'Troubadour',
  'class.dancer': 'Dancer',
  'class.greatLord': 'Great Lord',
  'class.swordmaster': 'Swordmaster',
  'class.assassin': 'Assassin',
  'class.rogue': 'Rogue',
  'class.hero': 'Hero',
  'class.warrior': 'Warrior',
  'class.berserker': 'Berserker',
  'class.ranger': 'Ranger',
  'class.sniper': 'Sniper',
  'class.general': 'General',
  'class.greatKnight': 'Great Knight',
  'class.paladin': 'Paladin',
  'class.falcoknight': 'Falcon Knight',
  'class.wyvernKnight': 'Wyvern Knight',
  'class.wyvernLord': 'Wyvern Lord',
  'class.sage': 'Sage',
  'class.mageKnight': 'Mage Knight',
  'class.druid': 'Druid',
  'class.summoner': 'Summoner',
  'class.bishop': 'Bishop',
  'class.valkyrie': 'Valkyrie',
  'class.superJourneyman': 'Champion',
  'class.superRecruit': 'Elite Guard',
  'class.superPupil': 'Archsage',
  'class.necromancer': 'Necromancer',
  'class.mamkute': 'Dragonkin',
  'trait.mounted': 'Mounted',
  'trait.armored': 'Armored',
  'trait.flying': 'Flying',
  'weaponType.sword': 'Sword',
  'weaponType.lance': 'Lance',
  'weaponType.axe': 'Axe',
  'weaponType.bow': 'Bow',
  'weaponType.magic': 'Magic',
  'item.heroCrest': 'Hero Crest',
  'item.knightCrest': 'Knight Crest',
  'item.guidingRing': 'Guiding Ring',
  'item.orionsBolt': "Orion's Bolt",
  'item.oceanSeal': 'Ocean Seal',
  'item.elysianWhip': 'Elysian Whip',
  'item.lunarBrace': 'Lunar Brace',
  'item.solarBrace': 'Solar Brace',
  'item.levelUp': 'Level 10',
  'skill.greatShield': 'Great Shield',
  'skill.pierce': 'Pierce',
  'skill.silencer': 'Silencer',
  'skill.sureShot': 'Sure Shot',
  'skill.slayer': 'Slayer',
  'skill.summon': 'Summon',
  'skill.crit15': 'Killer Instinct',
  'skill.steal': 'Steal',
  'skill.dance': 'Dance',
  'ui.attack': 'Attack',
  'ui.wait': 'Wait',
  'ui.cancel': 'Cancel',
  'ui.promote': 'Promote',
  'ui.choosePromotion': 'Choose a promotion',
  'ui.skill': 'Skill',
  'ui.subtitle': 'A turn-based tactical RPG',
  'ui.startCampaign': 'Start Campaign',
  'ui.turn': 'Turn',
  'ui.objective': 'Defeat all foes',
  'ui.playerPhase': 'Player Phase',
  'ui.enemyPhase': 'Enemy Phase',
  'ui.endTurn': 'End Turn',
  'ui.victory': 'Victory!',
  'ui.defeat': 'Defeat',
  'ui.playAgain': 'Play Again',
  'ui.nextChapter': 'Next Chapter',
  'ui.campaignComplete': 'Campaign Complete!',
  'ui.toTitle': 'To Title',
  'ui.tapUnitHint': 'Tap one of your (blue) units to act',
  'ui.selectTargetHint': 'Tap a highlighted enemy to attack',
  'ui.heal': 'Heal',
  'ui.item': 'Item',
  'ui.selectHealHint': 'Tap a wounded ally',
  'ui.back': 'Back',
};
