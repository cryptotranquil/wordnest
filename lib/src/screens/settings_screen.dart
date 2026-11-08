import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:wordnest/src/config/app_links.dart';
import 'package:wordnest/src/state/settings_state.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';
import 'package:wordnest/src/widgets/scenic_background.dart';

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
      backgroundColor: AppColors.glassLine.withValues(alpha: 0.9),
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
      backgroundColor: AppColors.glassLine.withValues(alpha: 0.9),
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
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ScenicBackground(scrim: SceneScrim.home),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildAudioSection(),
                      _buildAppearanceSection(),
                      _buildWordNestGuideSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Settings',
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
                  Icons.spa_rounded,
                  size: 16,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  'WordNest',
                  style: AppText.label(12, weight: FontWeight.w700, color: AppColors.gold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Audio & Sensory',
            style: AppText.label(14, weight: FontWeight.w700, color: AppColors.teal),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.glassLine.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListenableBuilder(
            listenable: SettingsState.instance,
            builder: (context, child) {
              return Column(
                children: [
                  _buildToggleItem(
                    icon: Icons.volume_up_rounded,
                    title: 'Sound Effects',
                    subtitle: 'Tile taps, chime resonances',
                    value: SettingsState.instance.soundOn,
                    onChanged: (value) => SettingsState.instance.setSoundOn(value),
                  ),
                  _buildToggleItem(
                    icon: Icons.music_note_rounded,
                    title: 'Ambient Harmonics',
                    subtitle: 'Tranquil stream & gentle pads',
                    value: SettingsState.instance.musicOn,
                    onChanged: (value) => SettingsState.instance.setMusicOn(value),
                  ),
                  _buildSliderItem(
                    icon: Icons.air_rounded,
                    title: 'Music Volume',
                    value: SettingsState.instance.musicVolume,
                    onChanged: (value) => SettingsState.instance.setMusicVolume(value),
                  ),
                  _buildToggleItem(
                    icon: Icons.vibration_rounded,
                    title: 'Tactile Pulse',
                    subtitle: 'Haptic rhythm on letter glide',
                    value: SettingsState.instance.hapticsOn,
                    onChanged: (value) => SettingsState.instance.setHapticsOn(value),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Appearance',
            style: AppText.label(14, weight: FontWeight.w700, color: AppColors.teal),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.glassLine.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListenableBuilder(
            listenable: SettingsState.instance,
            builder: (context, child) {
              return Column(
                children: [
                  _buildToggleItem(
                    icon: Icons.accessibility,
                    title: 'Reduce Motion',
                    subtitle: 'Minimize animations and effects',
                    value: SettingsState.instance.reduceMotion,
                    onChanged: (value) => SettingsState.instance.setReduceMotion(value),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWordNestGuideSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'WordNest Codex',
            style: AppText.label(14, weight: FontWeight.w700, color: AppColors.teal),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.glassLine.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildListItem(
                icon: Icons.menu_book_rounded,
                title: "Seeker's Guide & Mechanics",
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Seeker's Guide"),
                      content: const Text('A calm word cross puzzle. Swipe to connect letters and fill the crossword.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildListItem(
                icon: Icons.help_rounded,
                title: 'How to Play',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('How to Play'),
                      content: const Text('Drag from one letter to the next to build a word. Any order, any direction.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildListItem(
                icon: Icons.language_rounded,
                title: 'Word Lexicon',
                subtitle: 'English (US) • 85k Words',
                trailing: 'EN',
                onTap: _showLanguageBottomSheet,
              ),
              _buildListItem(
                icon: Icons.favorite_rounded,
                title: 'Wellness Reminders',
                subtitle: SettingsState.instance.reminderEnabled
                    ? 'Daily ${SettingsState.instance.reminderHour.toString().padLeft(2, '0')}:${SettingsState.instance.reminderMinute.toString().padLeft(2, '0')} PM'
                    : 'Off',
                onTap: _showWellnessReminderPicker,
              ),
              _buildListItem(
                icon: Icons.policy_rounded,
                title: 'Privacy & Terms',
                onTap: () => _launchUrl(AppLinks.privacyPolicy),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'WordNest v1.0.0',
            style: AppText.label(12, color: AppColors.muted),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onChanged(!value);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.glassLine.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.quicksand(16, color: AppColors.cream),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppText.label(12, color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: value,
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.teal;
                  }
                  return null;
                }),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderItem({
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onChanged(value);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.glassLine.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.quicksand(16, color: AppColors.cream),
                    ),
                  ],
                ),
              ),
              Slider(
                value: value,
                thumbColor: AppColors.teal,
                inactiveColor: AppColors.glassLine.withValues(alpha: 0.3),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.glassLine.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.quicksand(16, color: AppColors.cream),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppText.label(12, color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailing,
                  style: AppText.label(14, weight: FontWeight.w700, color: AppColors.teal),
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppColors.muted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}