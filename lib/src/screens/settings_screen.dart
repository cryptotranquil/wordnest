import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:wordnest/src/config/app_links.dart';
import 'package:wordnest/src/state/settings_state.dart';
import 'package:wordnest/src/services/sound_service.dart';
import 'package:wordnest/src/services/ad_consent_service.dart';
import 'package:wordnest/src/services/ad_service.dart';
import 'package:wordnest/src/widgets/ad_age_gate.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showInfo(BuildContext context, String title, String message) {
    showDialog<void>(context: context, builder: (context) => AlertDialog(
      title: Text(title), content: Text(message),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ));
  }

  Future<void> _openPrivacy(BuildContext context) async {
    final opened = await url_launcher.launchUrl(Uri.parse(AppLinks.privacyPolicy));
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  Future<void> _openAdPrivacyOptions(BuildContext context) async {
    final ads = AdService();
    final ageAllowed = await confirmAdAge(context, ads);
    if (!context.mounted) return;
    if (!ageAllowed) {
      if (ads.adsBlockedForAge) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ads are unavailable for players under 18.'),
        ));
      }
      return;
    }
    final consent = AdConsentService.instance;
    if (!consent.updatedThisSession) {
      await consent.prepare(canShow: () => context.mounted);
      if (!context.mounted) return;
    }
    if (!context.mounted) return;
    if (!consent.privacyOptionsRequired) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ad privacy options are not available right now.'),
      ));
      return;
    }
    final opened = await consent.showPrivacyOptions();
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad privacy options are unavailable. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsState.instance;
    final adConsent = AdConsentService.instance;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(child: ListenableBuilder(
        listenable: Listenable.merge([settings, adConsent]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Row(children: [
              Expanded(child: Text('Settings', style: AppText.quicksand(26, weight: 700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF1B3838), borderRadius: BorderRadius.circular(30)),
                child: Row(children: [const Icon(Icons.spa_outlined, color: AppColors.teal, size: 16), const SizedBox(width: 6), Text('WordNest', style: AppText.label(11))]),
              ),
            ]),
            const SizedBox(height: 28),
            const _SectionTitle('AUDIO & SENSORY'),
            _SettingsGroup(children: [
              _ToggleRow(icon: Icons.volume_up_outlined, title: 'Sound Effects', subtitle: 'Tile taps, chime resonances', value: settings.soundOn, onChanged: settings.setSoundOn),
              _ToggleRow(icon: Icons.music_note_outlined, title: 'Ambient Harmonics', subtitle: 'Tranquil stream & gentle pads', value: settings.musicOn, onChanged: settings.setMusicOn),
              _VolumeRow(value: settings.musicVolume, onChanged: settings.setMusicVolume),
              _ToggleRow(icon: Icons.vibration_outlined, title: 'Tactile Pulse', subtitle: 'Haptic rhythm on letter glide', value: settings.hapticsOn, onChanged: settings.setHapticsOn),
            ]),
            const SizedBox(height: 24),
            const _SectionTitle('APPEARANCE'),
            _SettingsGroup(children: [
              _ToggleRow(icon: Icons.waves_rounded, title: 'Reduce Motion', subtitle: 'Minimize animations and effects', value: settings.reduceMotion, onChanged: settings.setReduceMotion),
            ]),
            const SizedBox(height: 24),
            const _SectionTitle('WORDNEST CODEX'),
            _SettingsGroup(children: [
              _LinkRow(icon: Icons.menu_book_outlined, title: "Seeker's Guide & Mechanics", onTap: () => _showInfo(context, "Seeker's Guide", 'Swipe to connect letters and fill the crossword.')),
              _LinkRow(icon: Icons.help_outline_rounded, title: 'How to Play', onTap: () => _showInfo(context, 'How to Play', 'Drag from one letter to the next to build a word. Any order, any direction.')),
              _LinkRow(icon: Icons.language_rounded, title: 'Word Lexicon', subtitle: 'English (US)', onTap: () => _showInfo(context, 'Word Lexicon', 'English words are currently defined for each puzzle.')),
              _LinkRow(icon: Icons.favorite_border_rounded, title: 'Wellness Reminders', subtitle: 'Coming soon', onTap: () => _showInfo(context, 'Wellness Reminders', 'Reminders are not available yet.')),
              _LinkRow(icon: Icons.shield_outlined, title: 'Privacy & Terms', onTap: () => _openPrivacy(context)),
              if (AdService().isSupported)
                _LinkRow(icon: Icons.privacy_tip_outlined, title: 'Ad privacy options',
                  subtitle: 'Review your advertising choices',
                  onTap: () => _openAdPrivacyOptions(context)),
            ]),
            const SizedBox(height: 24),
            Center(child: Text('WordNest v0.1.0', style: AppText.label(11, color: AppColors.muted))),
          ],
        ),
      )),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(text, style: AppText.label(11, weight: 700, color: AppColors.teal, letterSpacing: 1)),
  );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Container(color: const Color(0xFF123130), child: Column(children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) Divider(height: 1, color: AppColors.muted.withValues(alpha: .16)),
        children[i],
      ],
    ])),
  );
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon(this.icon);
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(color: const Color(0xFF204947), borderRadius: BorderRadius.circular(13)),
    child: Icon(icon, color: AppColors.teal, size: 23),
  );
}

class _RowText extends StatelessWidget {
  const _RowText(this.title, this.subtitle);
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: AppText.quicksand(16, weight: 700)),
    if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle!, style: AppText.label(11, color: AppColors.muted, weight: 500))],
  ]);
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    child: Row(children: [
      _SettingsIcon(icon), const SizedBox(width: 12),
      Expanded(child: _RowText(title, subtitle)),
      Switch(value: value, onChanged: (newValue) {
        onChanged(newValue);
        SoundService.instance.play(SoundId.toggle);
      }, activeTrackColor: AppColors.teal, activeThumbColor: AppColors.ink),
    ]),
  );
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    child: Row(children: [
      const _SettingsIcon(Icons.tune_rounded), const SizedBox(width: 12),
      Expanded(child: Column(children: [
        Row(children: [Expanded(child: Text('Music Volume', style: AppText.quicksand(16, weight: 700))), Text('${(value * 100).round()}%', style: AppText.label(12, color: AppColors.muted))]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 4, overlayShape: SliderComponentShape.noOverlay),
          child: Slider(value: value, onChanged: onChanged, activeColor: AppColors.teal, inactiveColor: const Color(0xFF325451)),
        ),
      ])),
    ]),
  );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.icon, required this.title, this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(onTap: onTap, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        _SettingsIcon(icon), const SizedBox(width: 12),
        Expanded(child: _RowText(title, subtitle)),
        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ]),
    )),
  );
}
