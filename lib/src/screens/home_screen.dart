import 'dart:async';

import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../state/daily_reward_service.dart';
import '../state/player_state.dart';
import '../theme/wordnest_theme.dart';
import '../widgets/brand.dart';
import '../widgets/capsules.dart';
import '../widgets/scenic_background.dart';
import '../widgets/today_panel.dart';
import 'daily_reward_screen.dart';
import 'gameplay_screen.dart';

/// Home: brand, the current chapter's play disc and one Today panel.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.player});

  final PlayerState player;

  static const int chapterTotalLevels = 8;

  int get _cleared => (player.currentLevel - 8).clamp(0, chapterTotalLevels);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DailyRewardService _rewardService;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _rewardService = DailyRewardService(
      player: widget.player,
      now: () => DateTime.now(),
    );
    _startResetTimer();
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _startResetTimer() {
    final duration = _rewardService.timeUntilReset;
    _resetTimer?.cancel();
    _resetTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() {
        _rewardService = DailyRewardService(
          player: widget.player,
          now: () => DateTime.now(),
        );
      });
      _startResetTimer();
    });
  }

  void _openLevel(int number) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameplayScreen(
          level: LevelBook.level(number),
          player: widget.player,
        ),
      ),
    );
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openDailyReward() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, _, _) => DailyRewardScreen(
          player: widget.player,
          service: _rewardService,
        ),
        transitionsBuilder: (_, Animation<double> animation, _, Widget child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    ).then((_) {
      if (!mounted) return;
      // Refresh the service after reward screen pops
      setState(() {
        _rewardService = DailyRewardService(
          player: widget.player,
          now: () => DateTime.now(),
        );
      });
    });
  }

  String _formatTimeUntilReset() {
    final duration = _rewardService.timeUntilReset;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return 'Resets in ${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ScenicBackground(scrim: SceneScrim.home),
          SafeArea(
            child: AnimatedBuilder(
              animation: widget.player,
              builder: (BuildContext context, _) {
                return Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Wordmark(),
                          CoinPill(
                            coins: widget.player.coins,
                            onAdd: () => _notify(
                              'The coin shop is not designed yet.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Icon(
                                Icons.menu_book_rounded,
                                size: 15,
                                color: AppColors.tealLift,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Chapter 2',
                                style: AppText.label(
                                  12,
                                  weight: 600,
                                  color: AppColors.muted,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Misty Lake',
                                style: AppText.label(12, weight: 700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _PlayDisc(
                            onTap: () => _openLevel(widget.player.currentLevel),
                            level: widget.player.currentLevel,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Glass(
                                height: 26,
                                radius: 13,
                                padding: const EdgeInsets.symmetric(horizontal: 11),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      'Level ${widget.player.currentLevel}',
                                      style: AppText.label(11.5, weight: 700),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Row(
                                children: <Widget>[
                                  for (var i = 0; i < 3; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 3),
                                      child: Icon(
                                        Icons.star_rounded,
                                        size: 14,
                                        color: i < 2
                                            ? AppColors.gold
                                            : Colors.white.withValues(alpha: 0.22),
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _formatTimeUntilReset(),
                                    style: AppText.label(11, weight: 500, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: 280,
                            child: Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      'Levels cleared',
                                      style: AppText.label(
                                        10.5,
                                        weight: 600,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    Text.rich(
                                      TextSpan(
                                        children: <InlineSpan>[
                                          TextSpan(
                                            text: '${widget._cleared}',
                                            style: AppText.label(10.5, weight: 700),
                                          ),
                                          TextSpan(
                                            text: ' of ${HomeScreen.chapterTotalLevels}',
                                            style: AppText.label(
                                              10.5,
                                              weight: 600,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: SizedBox(
                                    height: 5,
                                    child: Stack(
                                      children: <Widget>[
                                        Positioned.fill(
                                          child: ColoredBox(
                                            color: Colors.white.withValues(alpha: 0.11),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: widget._cleared / HomeScreen.chapterTotalLevels,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: <Color>[
                                                  AppColors.teal,
                                                  Color(0xFF5FD8C9),
                                                  AppColors.gold,
                                                ],
                                                stops: <double>[0, 0.7, 1],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TodayPanel(
                        rows: <Widget>[
                          TodayRow(
                            icon: Icons.calendar_today_rounded,
                            title: 'Daily puzzle',
                            detail: 'Pine Vista #42',
                            actionLabel: 'Play',
                            onAction: () => _openLevel(1),
                            showDivider: false,
                          ),
                          _DailyRewardRow(
                            player: widget.player,
                            service: _rewardService,
                            onClaim: () => _openDailyReward(),
                          ),
                          TodayRow(
                            icon: Icons.workspace_premium_rounded,
                            title: 'Missions',
                            detail: '2 of 3 complete',
                            actionLabel: 'View',
                            onAction: () => _notify(
                              'Missions are not designed yet.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyRewardRow extends StatelessWidget {
  const _DailyRewardRow({
    required this.player,
    required this.service,
    required this.onClaim,
  });

  final PlayerState player;
  final DailyRewardService service;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return TodayRow(
      icon: Icons.workspace_premium_rounded,
      title: 'Daily Gift',
      detailHighlight: 'Day ${service.dayToClaim} ',
      detail: 'of 7',
      actionLabel: service.canClaimToday ? 'Claim' : 'Claimed',
      solidAction: service.canClaimToday,
      actionEnabled: service.canClaimToday,
      onAction: onClaim,
    );
  }
}

class _PlayDisc extends StatefulWidget {
  const _PlayDisc({required this.onTap, required this.level});

  final VoidCallback onTap;
  final int level;

  @override
  State<_PlayDisc> createState() => _PlayDiscState();
}

class _PlayDiscState extends State<_PlayDisc> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play level ${widget.level}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 140),
          child: SizedBox(
            width: 188,
            height: 188,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 228,
                  height: 228,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.tealLift.withValues(alpha: 0.07)),
                  ),
                ),
                Container(
                  width: 206,
                  height: 206,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.tealLift.withValues(alpha: 0.16)),
                  ),
                ),
                Container(
                  width: 188,
                  height: 188,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(0, -0.56),
                      radius: 0.92,
                      colors: <Color>[
                        Color(0xFF2FB0A1),
                        Color(0xFF0D6A62),
                        Color(0xFF09504B),
                      ],
                      stops: <double>[0, 0.56, 1],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.44),
                        offset: const Offset(0, 22),
                        blurRadius: 46,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.26),
                        offset: const Offset(0, -2),
                        blurRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.tealLift.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 34,
                        color: const Color(0xFFDFFAF5).withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PLAY',
                        style: AppText.quicksand(
                          26,
                          color: const Color(0xFFF2FFFD),
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
