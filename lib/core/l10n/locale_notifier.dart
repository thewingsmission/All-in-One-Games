import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Key used for persisting language in storage (must match settings_popup).
const String kSettingsLanguageKey = 'settings_language';

/// Notifier for app locale. Persists and loads language from storage.
class LocaleNotifier extends ChangeNotifier {
  LocaleNotifier({String? initialLanguageTag}) {
    final tag = initialLanguageTag;
    _languageTag = (tag == null || tag.isEmpty) ? 'en' : tag;
    _locale = _localeFromTag(_languageTag);
  }

  String _languageTag = 'en';
  late Locale _locale;

  String get languageTag => _languageTag;
  Locale get locale => _locale;

  static Locale _localeFromTag(String tag) {
    final parts = tag.split('_');
    if (parts.isEmpty) return const Locale('en');
    if (parts.length == 1) return Locale(parts[0]);
    return Locale(parts[0], parts[1]);
  }

  Future<void> setLocale(String languageTag) async {
    if (_languageTag == languageTag) return;
    final svc = await StorageService.getInstance();
    await svc.saveString(kSettingsLanguageKey, languageTag);
    _languageTag = languageTag;
    _locale = _localeFromTag(languageTag);
    notifyListeners();
  }
}
