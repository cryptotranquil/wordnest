
class Chapter {
  final int id;
  final String name;
  final String themeKey;
  final int levelStart;
  final int levelEnd;
  final int unlockAfterLevel;

  const Chapter({
    required this.id,
    required this.name,
    required this.themeKey,
    required this.levelStart,
    required this.levelEnd,
    required this.unlockAfterLevel,
  });
}

class ChapterBook {
  static const List<Chapter> chapters = [
    Chapter(
      id: 1,
      name: 'Whispering Forest',
      themeKey: 'forest',
      levelStart: 1,
      levelEnd: 20,
      unlockAfterLevel: 0,
    ),
    Chapter(
      id: 2,
      name: 'Ocean Serenity',
      themeKey: 'ocean',
      levelStart: 21,
      levelEnd: 40,
      unlockAfterLevel: 20,
    ),
    Chapter(
      id: 3,
      name: 'Celestial Cosmos',
      themeKey: 'cosmos',
      levelStart: 41,
      levelEnd: 60,
      unlockAfterLevel: 40,
    ),
  ];

  static Chapter? chapterForLevel(int level) {
    for (final chapter in chapters) {
      if (level >= chapter.levelStart && level <= chapter.levelEnd) {
        return chapter;
      }
    }
    return null;
  }

  static bool isChapterUnlocked(int chapterId, int currentLevel) {
    final chapter = chapters.firstWhere((c) => c.id == chapterId);
    return currentLevel > chapter.unlockAfterLevel;
  }
}