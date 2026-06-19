/// The ordered list of chapters that make up the campaign. Chapters are plain
/// JSON assets; progression is just an index into this list.
class Campaign {
  const Campaign._();

  static const List<String> chapters = [
    'assets/maps/chapter_1.json',
    'assets/maps/chapter_2.json',
  ];

  static bool hasNext(int index) => index + 1 < chapters.length;
}
