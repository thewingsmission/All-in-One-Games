import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/l10n/locale_notifier.dart';
import '../../core/l10n/app_localizations.dart';
import '../../shared/themes/app_theme.dart';

const List<Map<String, String>> _languageOptions = [
  {'code': 'en', 'label': 'English'},
  {'code': 'zh_TW', 'label': '繁體中文'},
  {'code': 'zh_CN', 'label': '简体中文'},
  {'code': 'es', 'label': 'Español'},
  {'code': 'fr', 'label': 'Français'},
  {'code': 'it', 'label': 'Italiano'},
  {'code': 'sv', 'label': 'Svenska'},
  {'code': 'de', 'label': 'Deutsch'},
  {'code': 'ja', 'label': '日本語'},
  {'code': 'ko', 'label': '한국어'},
  {'code': 'pt', 'label': 'Português'},
  {'code': 'ru', 'label': 'Русский'},
  {'code': 'nl', 'label': 'Nederlands'},
  {'code': 'pl', 'label': 'Polski'},
  {'code': 'tr', 'label': 'Türkçe'},
  {'code': 'ar', 'label': 'العربية'},
  {'code': 'hi', 'label': 'हिन्दी'},
  {'code': 'th', 'label': 'ไทย'},
  {'code': 'vi', 'label': 'Tiếng Việt'},
  {'code': 'id', 'label': 'Bahasa Indonesia'},
  {'code': 'el', 'label': 'Ελληνικά'},
  {'code': 'cs', 'label': 'Čeština'},
  {'code': 'ro', 'label': 'Română'},
  {'code': 'hu', 'label': 'Magyar'},
  {'code': 'da', 'label': 'Dansk'},
  {'code': 'no', 'label': 'Norsk'},
  {'code': 'fi', 'label': 'Suomi'},
];

const String _keyMusicVolume = 'settings_music_volume';
const String _keyAudioVolume = 'settings_audio_volume';

/// Shows a settings popup with music volume, audio volume, and language dropdown.
Future<void> showSettingsPopup(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => const _SettingsPopupDialog(),
  );
}

class _SettingsPopupDialog extends StatefulWidget {
  const _SettingsPopupDialog();

  @override
  State<_SettingsPopupDialog> createState() => _SettingsPopupDialogState();
}

class _SettingsPopupDialogState extends State<_SettingsPopupDialog> {
  double _musicVolume = 80;
  double _audioVolume = 80;
  String _language = 'en';
  double _initialMusicVolume = 80;
  double _initialAudioVolume = 80;
  String _initialLanguage = 'en';
  bool _loaded = false;
  bool get _dirty =>
      (_musicVolume != _initialMusicVolume) ||
      (_audioVolume != _initialAudioVolume) ||
      (_language != _initialLanguage);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final svc = await StorageService.getInstance();
    if (!mounted) return;
    setState(() {
      _musicVolume = (svc.getInt(_keyMusicVolume) ?? 80).toDouble();
      _audioVolume = (svc.getInt(_keyAudioVolume) ?? 80).toDouble();
      final saved = svc.getString(kSettingsLanguageKey);
      _language = (saved == null || saved.isEmpty) ? 'en' : saved;
      _initialMusicVolume = _musicVolume;
      _initialAudioVolume = _audioVolume;
      _initialLanguage = _language;
      _loaded = true;
    });
  }

  Future<void> _saveAll() async {
    final svc = await StorageService.getInstance();
    await svc.saveInt(_keyMusicVolume, _musicVolume.round());
    await svc.saveInt(_keyAudioVolume, _audioVolume.round());
    await svc.saveString(kSettingsLanguageKey, _language);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppTheme.primaryCyan;
    final t = (String key) => AppLocalizations.tr(context, key);
    if (!_loaded) {
      return AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: themeColor, width: 2),
        ),
        content: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(color: themeColor),
          ),
        ),
      );
    }
    return AlertDialog(
      backgroundColor: const Color(0xFF000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: themeColor, width: 2),
      ),
      title: Center(
        child: Text(
          t('settings'),
          style: TextStyle(
            color: themeColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Icon(Icons.music_note, color: themeColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('music_volume'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Slider(
                        value: _musicVolume,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        activeColor: themeColor,
                        onChanged: (v) {
                          setState(() => _musicVolume = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.volume_up, color: themeColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('audio_volume'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Slider(
                        value: _audioVolume,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        activeColor: themeColor,
                        onChanged: (v) {
                          setState(() => _audioVolume = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              t('language'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 280,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: themeColor, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: ListView.builder(
                    itemCount: _languageOptions.length,
                    itemBuilder: (context, index) {
                      final o = _languageOptions[index];
                      final code = o['code']!;
                      final label = o['label']!;
                      final isSelected = _language == code;
                      return InkWell(
                        onTap: () => setState(() => _language = code),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? themeColor.withOpacity(0.25) : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check, color: themeColor, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
      actions: _dirty
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  t('cancel'),
                  style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await _saveAll();
                  if (!context.mounted) return;
                  await context.read<LocaleNotifier>().setLocale(_language);
                  if (!context.mounted) return;
                  Navigator.pop(context, _language);
                },
                child: Text(
                  t('ok'),
                  style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  t('close'),
                  style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
    );
  }
}
