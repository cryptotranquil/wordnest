import 'package:flutter/material.dart';
import 'package:wordnest/src/data/chapter.dart';
import 'package:wordnest/src/data/levels.dart';
import 'package:wordnest/src/screens/gameplay_screen.dart';
import 'package:wordnest/src/state/player_state.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';
import 'package:wordnest/src/widgets/level_path_painter.dart';
import 'package:wordnest/src/widgets/scenic_background.dart';

class ChaptersScreen extends StatefulWidget {
  const ChaptersScreen({super.key, required this.player});

  final PlayerState player;

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  @override
  Widget build(BuildContext context) {
    final currentChapter = ChapterBook.chapterForLevel(widget.player.currentLevel) ?? ChapterBook.chapters.first;
    final progress = (widget.player.currentLevel - currentChapter.levelStart) / (currentChapter.levelEnd - currentChapter.levelStart + 1);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ScenicBackground(
            palette: _getBackgroundPalette(currentChapter.themeKey),
            scrim: SceneScrim.home,
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildCurrentChapterCard(currentChapter, progress),
                          _buildLevelPath(currentChapter),
                          _buildCompletedChapters(),
                          _buildLockedChapter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ScenePalette _getBackgroundPalette(String themeKey) {
    switch (themeKey) {
      case 'forest':
        return ScenePalette.dawn;
      case 'ocean':
        return ScenePalette.dusk;
      case 'cosmos':
        return ScenePalette.night;
      default:
        return ScenePalette.dawn;
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Chapters & Journey',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.glassLine.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_stories_rounded,
                  size: 16,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  'Ch. ${widget.player.currentChapter} • ${widget.player.currentLevel - ChapterBook.chapters[widget.player.currentChapter - 1].levelStart + 1}/${ChapterBook.chapters[widget.player.currentChapter - 1].levelEnd - ChapterBook.chapters[widget.player.currentChapter - 1].levelStart + 1}',
                  style: AppText.label(12, weight: FontWeight.w700, color: AppColors.gold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentChapterCard(Chapter chapter, double progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.glassLine.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: DecorationImage(
                image: AssetImage('assets/images/${chapter.themeKey}_background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.ink.withValues(alpha: 0.6),
                        AppColors.ink.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.explore_rounded,
                              size: 14,
                              color: AppColors.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Currently Exploring',
                              style: AppText.label(
                                10,
                                weight: FontWeight.w700,
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.glassLine.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.player.currentLevel - chapter.levelStart + 1} / ${chapter.levelEnd - chapter.levelStart + 1} Cleared',
                              style: AppText.label(
                                10,
                                weight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.name,
                  style: AppText.quicksand(22, color: AppColors.cream),
                ),
                const SizedBox(height: 4),
                Text(
                  'Levels ${chapter.levelStart} - ${chapter.levelEnd} • ${_getChapterThemeDescription(chapter.themeKey)}',
                  style: AppText.label(14, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.glassLine.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getChapterThemeDescription(String themeKey) {
    switch (themeKey) {
      case 'forest':
        return 'Whispering Woods';
      case 'ocean':
        return 'Azure Deep Waters';
      case 'cosmos':
        return 'Stellar Night Sky';
      default:
        return 'Mystical Realm';
    }
  }

  Widget _buildLevelPath(Chapter chapter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: CustomPaint(
              painter: LevelPathPainter(
                currentLevel: widget.player.currentLevel,
                chapter: chapter,
              ),
              child: Center(
                child: _buildLevelNodes(chapter),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelNodes(Chapter chapter) {
    final levelCount = chapter.levelEnd - chapter.levelStart + 1;
    final spacing = 60.0;

    return Stack(
      children: List.generate(levelCount, (index) {
        final level = chapter.levelStart + index;
        final isCleared = level < widget.player.currentLevel;
        final isCurrent = level == widget.player.currentLevel;
        final isLocked = level > widget.player.currentLevel;

        return Positioned(
          left: index * spacing,
          top: index % 2 == 0 ? 100 : 150,
          child: GestureDetector(
            onTap: isCurrent ? () => _openLevel(level) : isCleared ? () => _replayLevel(level) : null,
            child: _buildLevelNode(level, isCleared, isCurrent, isLocked),
          ),
        );
      }),
    );
  }

  Widget _buildLevelNode(int level, bool isCleared, bool isCurrent, bool isLocked) {
    if (isCurrent) {
      return Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.gold, AppColors.gold.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$level',
                style: AppText.label(16, weight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current',
            style: AppText.label(12, weight: FontWeight.w600, color: AppColors.gold),
          ),
        ],
      );
    } else if (isCleared) {
      return Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal.withValues(alpha: 0.7),
              border: Border.all(color: AppColors.cream, width: 2),
            ),
            child: Center(
              child: Icon(
                Icons.check,
                size: 20,
                color: AppColors.cream,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cleared',
            style: AppText.label(12, weight: FontWeight.w600, color: AppColors.teal),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.glassLine.withValues(alpha: 0.3),
              border: Border.all(color: AppColors.muted, width: 1),
            ),
            child: Center(
              child: Text(
                '$level',
                style: AppText.label(14, weight: FontWeight.w500, color: AppColors.muted),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Locked',
            style: AppText.label(12, weight: FontWeight.w600, color: AppColors.muted),
          ),
        ],
      );
    }
  }

  void _openLevel(int level) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameplayScreen(
          level: LevelBook.level(level),
          player: widget.player,
        ),
      ),
    );
  }

  void _replayLevel(int level) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameplayScreen(
          level: LevelBook.level(level),
          player: widget.player,
        ),
      ),
    );
  }

  Widget _buildCompletedChapters() {
    final completedChapters = ChapterBook.chapters
        .where((c) => c.levelEnd < widget.player.currentLevel)
        .toList();

    if (completedChapters.isEmpty) return Container();

    return Column(
      children: completedChapters.map((chapter) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.glassLine.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.name,
                        style: AppText.quicksand(18, color: AppColors.cream),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Levels ${chapter.levelStart} - ${chapter.levelEnd} • Completed',
                        style: AppText.label(12, color: AppColors.teal),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Revisit the chapter
                    final firstLevel = chapter.levelStart;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GameplayScreen(
                          level: LevelBook.level(firstLevel),
                          player: widget.player,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.glassLine,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Revisit',
                    style: AppText.label(12, weight: FontWeight.w700, color: AppColors.cream),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLockedChapter() {
    final nextChapter = ChapterBook.chapters.firstWhere(
      (c) => c.levelStart > widget.player.currentLevel,
      orElse: () => ChapterBook.chapters.last,
    );

    if (nextChapter.levelStart <= widget.player.currentLevel) return Container();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.glassLine.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock,
                  size: 20,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextChapter.name,
                        style: AppText.quicksand(18, color: AppColors.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Levels ${nextChapter.levelStart} - ${nextChapter.levelEnd} • Locked',
                        style: AppText.label(12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Unlocks upon completing Level ${nextChapter.unlockAfterLevel}',
              style: AppText.label(12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}