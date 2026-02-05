import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../shared/themes/app_theme.dart';

/// Language option for dropdown
class _LangOption {
  final String code;
  final String label;
  const _LangOption(this.code, this.label);
}

const List<_LangOption> _languageOptions = [
  _LangOption('en', 'English'),
  _LangOption('zh_TW', '繁體中文'),
  _LangOption('zh_CN', '簡體中文'),
  _LangOption('es', 'Español'),
  _LangOption('fr', 'Français'),
  _LangOption('it', 'Italiano'),
  _LangOption('sv', 'Svenska'),
];

const String _keyMusicVolume = 'settings_music_volume';
const String _keyAudioVolume = 'settings_audio_volume';
const String _keyLanguage = 'settings_language';

/// Settings screen - Number Link style
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _musicVolume = 80;
  double _audioVolume = 80;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final svc = await StorageService.getInstance();
    setState(() {
      _musicVolume = (svc.getInt(_keyMusicVolume) ?? 80).toDouble();
      _audioVolume = (svc.getInt(_keyAudioVolume) ?? 80).toDouble();
      _language = svc.getString(_keyLanguage) ?? 'en';
    });
  }

  Future<void> _saveMusicVolume(double v) async {
    final svc = await StorageService.getInstance();
    await svc.saveInt(_keyMusicVolume, v.round());
  }

  Future<void> _saveAudioVolume(double v) async {
    final svc = await StorageService.getInstance();
    await svc.saveInt(_keyAudioVolume, v.round());
  }

  Future<void> _saveLanguage(String code) async {
    final svc = await StorageService.getInstance();
    await svc.saveString(_keyLanguage, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App info section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryCyan, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ABOUT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppTheme.primaryCyan,
                  ),
                ),
                const SizedBox(height: 16),
                _SettingItem(
                  icon: Icons.info_outline,
                  title: 'APP NAME',
                  subtitle: 'All-in-One Games - Play & Win',
                  iconColor: AppTheme.primaryCyan,
                ),
                _SettingItem(
                  icon: Icons.code,
                  title: 'VERSION',
                  subtitle: '1.0.0',
                  iconColor: AppTheme.primaryCyan,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Music & Audio volume + Language
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryOrange, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PREFERENCES',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.music_note, color: AppTheme.primaryOrange, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MUSIC VOLUME',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: Colors.white,
                            ),
                          ),
                          Slider(
                            value: _musicVolume,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            activeColor: AppTheme.primaryOrange,
                            onChanged: (v) {
                              setState(() => _musicVolume = v);
                              _saveMusicVolume(v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.volume_up, color: AppTheme.primaryOrange, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AUDIO VOLUME',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: Colors.white,
                            ),
                          ),
                          Slider(
                            value: _audioVolume,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            activeColor: AppTheme.primaryOrange,
                            onChanged: (v) {
                              setState(() => _audioVolume = v);
                              _saveAudioVolume(v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'LANGUAGE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryOrange, width: 1),
                  ),
                  child: DropdownButton<String>(
                    value: _languageOptions.any((o) => o.code == _language) ? _language : 'en',
                    isExpanded: true,
                    dropdownColor: AppTheme.backgroundColor,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: _languageOptions.map((o) {
                      return DropdownMenuItem<String>(
                        value: o.code,
                        child: Text(o.label),
                      );
                    }).toList(),
                    onChanged: (String? code) {
                      if (code != null) {
                        setState(() => _language = code);
                        _saveLanguage(code);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Support section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.neonGreen, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUPPORT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppTheme.neonGreen,
                  ),
                ),
                const SizedBox(height: 16),
                _SettingButtonItem(
                  icon: Icons.rate_review,
                  title: 'RATE APP',
                  onTap: () {
                    // TODO: Implement rating
                  },
                  iconColor: AppTheme.neonGreen,
                ),
                _SettingButtonItem(
                  icon: Icons.share,
                  title: 'SHARE APP',
                  onTap: () {
                    // TODO: Implement sharing
                  },
                  iconColor: AppTheme.neonGreen,
                ),
                _SettingButtonItem(
                  icon: Icons.help_outline,
                  title: 'HELP & FAQ',
                  onTap: () {
                    // TODO: Implement help
                  },
                  iconColor: AppTheme.neonGreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.3,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingSwitchItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;
  final Color accentColor;

  const _SettingSwitchItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.3,
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: accentColor,
          activeTrackColor: accentColor.withOpacity(0.5),
        ),
      ],
    );
  }
}

class _SettingButtonItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;

  const _SettingButtonItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: iconColor, size: 16),
          ],
        ),
      ),
    );
  }
}
