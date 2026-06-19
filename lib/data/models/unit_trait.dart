/// Body / movement traits shared by classes and referenced by weapons (for
/// effectiveness). Kept in its own file so `weapon.dart` and `unit_class.dart`
/// can both depend on it without a circular import.
///
/// A class can have several: a Great Knight is both [mounted] and [armored],
/// so it takes effective damage from anti-cavalry AND anti-armor weapons. Foot
/// units have an empty trait set.
enum UnitTrait { mounted, armored, flying }
