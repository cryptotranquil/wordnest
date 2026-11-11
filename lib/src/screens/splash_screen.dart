import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../state/daily_reward_service.dart';
import '../state/player_state.dart';
import '../theme/wordnest_theme.dart';
import '../widgets/brand.dart';
import '../widgets/scenic_background.dart';
import 'daily_reward_screen.dart';
import 'app_shell.dart';

/// Wordnest lockup over the chapter scenery, with a loading bar that
/// auto-advances to Home — no button, as decided for the MVP.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.player, this.ready});

  final PlayerState player;
  final Future<void>? ready;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Duration _hold = Duration(milliseconds: 2400);
  Timer? _timer;
  late final AnimationController _introController;
  late final AnimationController _breathController;
  late final Animation<double> _introFade;
  late final Animation<Offset> _introSlide;
  bool _rewardScreenShown = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _introFade = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    _introSlide = Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );
    _timer = Timer(_hold, _goHome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _introController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _goHome() async {
    try {
      await widget.ready;
    } catch (error) {
      debugPrint('Startup failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load saved progress. Please restart the app.')));
      }
      return;
    }
    if (!mounted) return;

    final service = DailyRewardService(
      player: widget.player,
      now: () => DateTime.now(),
    );

    // Check if we can claim today AND we haven't shown the reward screen yet
    if (service.canClaimToday && !_rewardScreenShown) {
      // Mark that we're about to show the reward screen
      setState(() => _rewardScreenShown = true);
      _pushRewardScreen();
    } else {
      _pushAppShell();
    }
  }

  Future<void> _pushRewardScreen() async {
    await Navigator.of(context).push(
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, _, _) => DailyRewardScreen(
          player: widget.player,
          service: DailyRewardService(
            player: widget.player,
            now: () => DateTime.now(),
          ),
        ),
        transitionsBuilder: (_, Animation<double> animation, _, Widget child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );

    // After reward screen pops, go to home screen
    _pushAppShell();
  }

  void _pushAppShell() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, _, _) => AppShell(player: widget.player),
        transitionsBuilder: (_, Animation<double> animation, _, Widget child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ScenicBackground(
            palette: ScenePalette.dawn,
            scrim: SceneScrim.splash,
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _introFade,
              child: SlideTransition(
                position: _introSlide,
                child: Column(
                  children: <Widget>[
                    const Spacer(flex: 3),
                    _Emblem(pulse: _breathController),
                    const SizedBox(height: 26),
                    Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text: 'Wordnest',
                            style: AppText.quicksand(
                              35,
                              color: AppColors.cream,
                              letterSpacing: -0.6,
                            ),
                          ),
                          TextSpan(
                            text: '.',
                            style: AppText.quicksand(35, color: AppColors.gold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ZEN WORD PUZZLE',
                      style: AppText.label(
                        10,
                        weight: 700,
                        color: AppColors.tealLift.withValues(alpha: 0.72),
                        letterSpacing: 3.4,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      '“Take your time.”',
                      style: AppText.label(
                        13,
                        weight: 500,
                        color: Colors.white.withValues(alpha: 0.6),
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 34),
                    _Loader(duration: _hold),
                    const Spacer(flex: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 34),
                      child: FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final version = snapshot.data?.version ?? '1.0.0';
                          return Text(
                            'WordNest v$version',
                            style: AppText.label(
                              11,
                              weight: 500,
                              color: AppColors.muted.withValues(alpha: 0.75),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (BuildContext context, Widget? child) {
        return SizedBox(
          width: 136,
          height: 136,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Transform.scale(
                scale: 0.94 + pulse.value * 0.06,
                child: Container(
                  width: 184,
                  height: 184,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        AppColors.tealLift.withValues(
                          alpha: 0.16 + pulse.value * 0.1,
                        ),
                        AppColors.teal.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const <double>[0, 0.58, 0.78],
                    ),
                  ),
                ),
              ),
              Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.tealLift.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.tealLift.withValues(alpha: 0.1),
                  ),
                ),
              ),
              const BrandMark(size: 96),
            ],
          ),
        );
      },
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.linear,
      builder: (BuildContext context, double value, _) {
        String message;
        if (value < 0.35) {
          message = 'GATHERING LETTERS';
        } else if (value < 0.76) {
          message = 'PREPARING YOUR WORDNEST';
        } else {
          message = 'ALMOST READY';
        }

        return Column(
          children: <Widget>[
            SizedBox(
              width: 196,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.white.withValues(alpha: 0.13),
                        ),
                      ),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: <Color>[
                                AppColors.teal,
                                Color(0xFF5FD8C9),
                                AppColors.gold,
                              ],
                              stops: <double>[0, 0.62, 1],
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: const Color(0xFF5FD8C9)
                                    .withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Row(
                key: ValueKey<String>(message),
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (final opacity in <double>[0.7, 0.5, 0.3])
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.tealLift.withValues(alpha: opacity),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    message,
                    style: AppText.label(
                      10,
                      weight: 600,
                      color: AppColors.muted,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
