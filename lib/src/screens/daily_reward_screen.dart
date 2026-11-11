import 'package:flutter/material.dart';

import '../data/daily_rewards.dart';
import '../state/daily_reward_service.dart';
import '../services/sound_service.dart';
import '../state/player_state.dart';
import '../theme/wordnest_theme.dart';
import '../widgets/capsules.dart';
import '../widgets/scenic_background.dart';

const bool kShowDoubleReward = false;

class DailyRewardScreen extends StatefulWidget {
  const DailyRewardScreen({
    super.key,
    required this.player,
    required this.service,
  });

  final PlayerState player;
  final DailyRewardService service;

  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen> {
  int _animatingCoins = 0;
  bool _buttonPressed = false;

  @override
  void initState() {
    super.initState();
    _animatingCoins = widget.player.coins;
  }

  void _playBurst(BuildContext context, Offset offset) {
    if (MediaQuery.of(context).disableAnimations) return;
    for (int i = 0; i < 12; i++) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }
  }

  Future<void> _animateCoins(int targetCoins) async {
    final start = _animatingCoins;
    final end = targetCoins;
    final duration = const Duration(milliseconds: 800);

    final startTime = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final now = DateTime.now().microsecondsSinceEpoch;
      final elapsed = (now - startTime) / 1000000;
      final t = (elapsed / (duration.inMilliseconds / 1000)).clamp(0.0, 1.0);
      if (!mounted) return;

      if (t >= 1) {
        setState(() {
          _animatingCoins = end;
        });
        break;
      }

      final current = start + ((end - start) * t).round();
      if (current != _animatingCoins) {
        setState(() {
          _animatingCoins = current;
        });
      }
      await Future.delayed(const Duration(milliseconds: 16));
    }
  }

  Future<void> _handleClaim() async {
    if (_buttonPressed) return;
    setState(() => _buttonPressed = true);

    final claimedReward = widget.service.claim();
    if (claimedReward == null) {
      setState(() => _buttonPressed = false);
      return;
    }

    SoundService.instance.play(SoundId.rewardClaim);
    if (mounted) {
      _playBurst(context, Offset.infinite);
    }

    await _animateCoins(widget.player.coins);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  DailyReward _rewardForDay(int day) {
    final cycle = widget.service.cycleToClaim;
    return rewardFor(cycle, day);
  }

  bool _isClaimed(int day) {
    if (widget.player.lastClaimDate == null) return false;
    final claimedDay = widget.player.claimedDay;
    return day < claimedDay;
  }

  bool _isToday(int day) {
    final today = widget.service.dayToClaim;
    return day == today;
  }

  bool _isLocked(int day) {
    return !_isClaimed(day) && !_isToday(day);
  }

  Widget _rewardIcon(DailyReward reward, {double size = 16}) {
    if (reward.coins > 0 && reward.hints > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.local_fire_department_rounded, size: size * 0.7, color: AppColors.gold),
          const SizedBox(width: 1),
          Icon(Icons.lightbulb_rounded, size: size, color: AppColors.tealLift),
        ],
      );
    } else if (reward.coins > 0 && reward.targets > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.local_fire_department_rounded, size: size * 0.7, color: AppColors.gold),
          const SizedBox(width: 1),
          Icon(Icons.center_focus_strong_rounded, size: size, color: AppColors.gold),
        ],
      );
    } else if (reward.hints > 0) {
      return Icon(Icons.lightbulb_rounded, size: size, color: AppColors.tealLift);
    } else if (reward.targets > 0) {
      return Icon(Icons.center_focus_strong_rounded, size: size, color: AppColors.gold);
    } else {
      return Icon(Icons.local_fire_department_rounded, size: size, color: AppColors.gold);
    }
  }

  Widget _buildDayCell(int day) {
    final reward = _rewardForDay(day);
    final isClaimed = _isClaimed(day);
    final isToday = _isToday(day);
    final isLocked = _isLocked(day);
    final isGrandChest = day == 7;

    if (isGrandChest) {
      return Container(
        width: 80,
        height: 72,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.glassLine.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('$day', style: AppText.label(8, weight: 700, color: AppColors.cream)),
            Icon(Icons.card_giftcard_rounded, size: 18, color: AppColors.gold),
            Text('+500', style: AppText.label(8, weight: 700)),
            if (!isClaimed && !isToday) Icon(Icons.lock_rounded, size: 10, color: AppColors.muted),
          ],
        ),
      );
    }

    final scale = isToday ? 1.05 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 200),
      child: Opacity(
        opacity: isLocked ? 0.75 : 1.0,
        child: Container(
          width: 60,
          height: 68,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isToday ? AppColors.teal : AppColors.glassLine.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isToday ? <BoxShadow>[BoxShadow(color: AppColors.gold.withValues(alpha: 0.35), blurRadius: 12)] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('$day', style: AppText.label(6, weight: 500, color: isToday ? AppColors.cream : AppColors.muted)),
                  if (isClaimed) Icon(Icons.check_circle_rounded, size: 8, color: AppColors.teal),
                ],
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: AppColors.glassLine.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Center(child: _rewardIcon(reward, size: 10)),
              ),
              Text(
                reward.coins > 0 ? '+${reward.coins}' : reward.hints > 0 ? '+1' : reward.targets > 0 ? '+1' : '',
                style: AppText.label(8, weight: 500, color: isToday ? AppColors.cream : AppColors.muted),
              ),
              Text(
                isClaimed ? 'c' : isToday ? 'TODAY' : '',
                style: AppText.label(6, weight: 700, color: isClaimed ? AppColors.teal : (isToday ? AppColors.gold : AppColors.muted)),
              ),
              if (isLocked && !isClaimed && !isToday) Icon(Icons.lock_rounded, size: 8, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayToClaim = widget.service.dayToClaim;
    final cycle = widget.service.cycleToClaim;
    final reward = rewardFor(cycle, dayToClaim);

    final parts = <String>[];
    if (reward.coins > 0) parts.add('+${reward.coins} Coins');
    if (reward.hints > 0) parts.add('+${reward.hints} Hints');
    if (reward.targets > 0) parts.add('+${reward.targets} Bullseye');
    final actionLabel = parts.join(' ');

    final daysGrid = Column(
      children: <Widget>[
        Row(children: <Widget>[for (int d = 1; d <= 4; d++) Expanded(child: _buildDayCell(d))]),
        const SizedBox(height: 6),
        Row(children: <Widget>[Expanded(child: _buildDayCell(5)), const SizedBox(width: 4), Expanded(child: _buildDayCell(6)), const SizedBox(width: 4), Expanded(child: _buildDayCell(7))]),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ScenicBackground(palette: ScenePalette.dusk, scrim: SceneScrim.sheet),
          Positioned(top: 16, right: 16, child: Semantics(button: true, label: 'Close', child: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.glassLine.withValues(alpha: 0.15), shape: BoxShape.circle), child: Center(child: GestureDetector(onTap: () => Navigator.of(context).pop(), child: Icon(Icons.close_rounded, size: 20, color: AppColors.text)))))),
          Positioned(top: 16, left: 16, child: CoinPill(coins: _animatingCoins)),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Container(
                  decoration: BoxDecoration(color: AppColors.glassLine.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.glassLine.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: Row(
                              children: <Widget>[
                                Text('🔥', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text('Day $dayToClaim Streak', style: AppText.label(10, weight: 700, color: AppColors.gold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.spa_rounded, size: 14, color: AppColors.gold),
                              const SizedBox(width: 4),
                              Text('Daily Gift', style: AppText.quicksand(12, weight: 600)),
                              Icon(Icons.spa_rounded, size: 14, color: AppColors.gold),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Come back each day.', style: AppText.label(9, weight: 500, color: AppColors.muted, height: 1.4), textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          daysGrid,
                          const SizedBox(height: 10),
                          if (widget.service.canClaimToday)
                            GestureDetector(
                              onTap: _handleClaim,
                              child: Container(
                                width: double.infinity,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: <Color>[AppColors.gold, AppColors.gold.withValues(alpha: 0.9)]),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: <BoxShadow>[BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), offset: const Offset(0, 4), blurRadius: 12)],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.goldInk),
                                    const SizedBox(width: 4),
                                    Flexible(child: Text(actionLabel, style: AppText.label(9, weight: 700, color: AppColors.goldInk))),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(width: double.infinity, height: 40, decoration: BoxDecoration(color: AppColors.glassLine.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)), alignment: Alignment.center, child: Text('Come back tomorrow', style: AppText.label(9, weight: 700, color: AppColors.muted))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.glassLine.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.play_circle_rounded, size: 12, color: AppColors.gold),
                                const SizedBox(width: 4),
                                Text('Double to +300', style: AppText.label(8, weight: 500, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Consistency is the gentle path to wisdom.', style: AppText.label(8, weight: 500, color: AppColors.muted.withValues(alpha: 0.7), height: 1.5), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
