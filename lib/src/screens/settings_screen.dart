import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:wordnest/src/config/app_links.dart';
import 'package:wordnest/src/state/settings_state.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';
import 'package:wordnest/src/widgets/panel_kit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await url_launcher.canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
      return;
    }
    await url_launcher.launchUrl(uri);
  }

  Future<void> _showLanguageBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: PanelColors.card,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Word Lexicon',
                style: AppText.quicksand(20, color: AppColors.cream),
              ),
            ),
            ListTile(
              title: const Text('English (US)'),
              subtitle: const Text('85,000 words'),
              trailing: const Icon(Icons.check, color: AppColors.gold),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              onTap: () => Navigator.pop(context),
              title: const Text('More languages coming soon'),
              trailing: const Icon(Icons.construction, color: AppColors.muted),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showWellnessReminderPicker() async {
    final settings = SettingsState.instance;
    final isEnabled = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: PanelColors.card,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Wellness Reminders',
                  style: AppText.quicksand(20, color: AppColors.cream),
                ),
              ),
              ListTile(
                title: const Text('Enable Reminders'),
                trailing: Switch(
                  value: settings.reminderEnabled,
                  onChanged: (value) {
                    Navigator.pop(context, value);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    // If dismissed without choosing
    if (isEnabled == null) return;

    if (isEnabled && mounted) {
      // Show time picker
      final newHour = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: settings.reminderHour, minute: settings.reminderMinute),
      );

      if (newHour != null && mounted) {
        settings.setReminderEnabled(true);
        settings.setReminderHour(newHour.hour);
        settings.setReminderMinute(newHour.minute);

        // Try to schedule notification
        if (_tryScheduleNotification()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Daily reminder set for ${newHour.format(context)}')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reminders work on the phone app')),
            );
          }
        }
      }
    } else {
      settings.setReminderEnabled(false);
    }
  }

  bool _tryScheduleNotification() {
    // Notification scheduling requires flutter_local_notifications
    // This is a placeholder - actual implementation would go here
    // On web or when scheduling is not available, we just save the setting
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PanelColors.bgBottom,
      body: PanelBackdrop(
        child: SafeArea(
          bottom: false,
          child: PhoneFrame(
            child: Column(
              children: <Widget>[
                const ScreenHeader(
                  title: 'Settings',
                  trailing: HeaderPill(label: 'WordNest', icon: Icons.eco_rounded),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    children: <Widget>[
                      _sectionLabel('Audio & Sensory'),
                      _buildAudioSection(),
                      const SizedBox(height: 22),
                      _sectionLabel('Appearance'),
                      _buildAppearanceSection(),
                      const SizedBox(height: 22),
                      _sectionLabel('WordNest Codex'),
                      _buildCodexSection(),
                      const SizedBox(height: 26),
                      Center(
                        child: Text(
                          'WordNest v1.0.0',
                          style: AppText.label(13, weight: 500, color: AppColors.muted),
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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
      child: Text(
        text.toUpperCase(),
        style: AppText.label(
          12.5,
          weight: 700,
          color: AppColors.teal,
          letterSpacing: 1.6,
        ),
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        indent: 16,
        endIndent: 16,
        color: PanelColors.divider,
      );

  Widget _buildAudioSection() {
    return PanelCard(
      child: ListenableBuilder(
        listenable: SettingsState.instance,
        builder: (BuildContext context, Widget? child) {
          final SettingsState s = SettingsState.instance;
          return Column(
            children: <Widget>[
              _toggleRow(
                icon: Icons.volume_up_rounded,
                title: 'Sound Effects',
                subtitle: 'Tile taps, chime resonances',
                value: s.soundOn,
                onChanged: s.setSoundOn,
              ),
              _divider(),
              _toggleRow(
                icon: Icons.music_note_rounded,
                title: 'Ambient Harmonics',
                subtitle: 'Tranquil stream & gentle pads',
                value: s.musicOn,
                onChanged: s.setMusicOn,
              ),
              _divider(),
              _volumeRow(s),
              _divider(),
              _toggleRow(
                icon: Icons.vibration_rounded,
                title: 'Tactile Pulse',
                subtitle: 'Haptic rhythm on letter glide',
                value: s.hapticsOn,
                onChanged: s.setHapticsOn,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return PanelCard(
      child: ListenableBuilder(
        listenable: SettingsState.instance,
        builder: (BuildContext context, Widget? child) {
          final SettingsState s = SettingsState.instance;
          return _toggleRow(
            icon: Icons.waves_rounded,
            title: 'Reduce Motion',
            subtitle: 'Minimize animations and effects',
            value: s.reduceMotion,
            onChanged: s.setReduceMotion,
          );
        },
      ),
    );
  }

  Widget _buildCodexSection() {
    final SettingsState s = SettingsState.instance;
    return PanelCard(
      child: ListenableBuilder(
        listenable: s,
        builder: (BuildContext context, Widget? child) {
          final String reminderText = s.reminderEnabled
              ? 'Daily ${_formatTime(s.reminderHour, s.reminderMinute)}'
              : 'Off';
          return Column(
            children: <Widget>[
              _navRow(
                icon: Icons.menu_book_rounded,
                title: "Seeker's Guide & Mechanics",
                onTap: () => _showInfo(
                  "Seeker's Guide",
                  'A calm word cross puzzle. Swipe to connect letters and fill the crossword. '
                      'Bonus words that are not in the grid still earn you coins.',
                ),
              ),
              _divider(),
              _navRow(
                icon: Icons.help_outline_rounded,
                title: 'How to Play',
                onTap: () => _showInfo(
                  'How to Play',
                  'Drag from one letter to the next to build a word. Any order, any direction.',
                ),
              ),
              _divider(),
              _navRow(
                icon: Icons.public_rounded,
                title: 'Word Lexicon',
                subtitle: 'English (US) · 85k words',
                onTap: _showLanguageBottomSheet,
              ),
              _divider(),
              _navRow(
                icon: Icons.favorite_border_rounded,
                title: 'Wellness Reminders',
                subtitle: reminderText,
                onTap: _showWellnessReminderPicker,
              ),
              _divider(),
              _navRow(
                icon: Icons.shield_outlined,
                title: 'Privacy & Terms',
                onTap: () => _launchUrl(AppLinks.privacyPolicy),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final int h12 = hour % 12 == 0 ? 12 : hour % 12;
    final String suffix = hour >= 12 ? 'PM' : 'AM';
    return '$h12:${minute.toString().padLeft(2, '0')} $suffix';
  }

  Future<void> _showInfo(String title, String body) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: PanelColors.card,
        title: Text(title, style: AppText.quicksand(20, weight: 700)),
        content: Text(body, style: AppText.label(14, weight: 500, color: AppColors.muted)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ rows

  Widget _rowText(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppText.quicksand(17, weight: 700, color: Colors.white)),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 3),
          Text(subtitle, style: AppText.label(13, weight: 500, color: AppColors.muted)),
        ],
      ],
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            IconTile(icon: icon),
            const SizedBox(width: 14),
            Expanded(child: _rowText(title, subtitle)),
            const SizedBox(width: 8),
            _toggle(value, onChanged),
          ],
        ),
      ),
    );
  }

  Widget _toggle(bool value, ValueChanged<bool> onChanged) {
    return Switch(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
        return states.contains(WidgetState.selected)
            ? PanelColors.bgBottom
            : const Color(0xFFC9D2D2);
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
        return states.contains(WidgetState.selected)
            ? AppColors.teal
            : const Color(0xFF3A4B4C);
      }),
      trackOutlineColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    );
  }

  Widget _volumeRow(SettingsState s) {
    final int pct = (s.musicVolume * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IconTile(icon: Icons.tune_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 11),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Music Volume',
                          style: AppText.quicksand(17, weight: 700, color: Colors.white),
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: AppText.label(13.5, weight: 600, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    activeTrackColor: AppColors.teal,
                    inactiveTrackColor: PanelColors.track,
                    thumbColor: Colors.white,
                    overlayColor: AppColors.teal.withValues(alpha: 0.12),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: s.musicVolume.clamp(0.0, 1.0),
                    onChanged: s.setMusicVolume,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            IconTile(icon: icon),
            const SizedBox(width: 14),
            Expanded(child: _rowText(title, subtitle)),
            const Icon(Icons.chevron_right_rounded, size: 26, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
