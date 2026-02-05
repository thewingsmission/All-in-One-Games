import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/navigation/app_router.dart';
import 'core/l10n/locale_notifier.dart';
import 'shared/themes/app_theme.dart';
import 'core/services/storage_service.dart';
import 'games/number_link/models/game_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize storage service and starting tokens (1000 if first run)
  final storage = await StorageService.getInstance();
  if (!storage.containsKey(StorageService.tokenKey)) {
    await storage.saveInt(StorageService.tokenKey, 1000);
  }
  
  // Load saved language for locale; default is English
  String? initialLanguageTag = storage.getString(kSettingsLanguageKey);
  if (initialLanguageTag == null || initialLanguageTag.isEmpty) {
    initialLanguageTag = 'en';
    await storage.saveString(kSettingsLanguageKey, 'en');
  }
  
  // Initialize Firebase (for leaderboards and other features)
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('⚠️ Firebase initialization failed: $e');
    print('   (Leaderboard features will be disabled)');
  }
  
  runApp(MyApp(initialLanguageTag: initialLanguageTag));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialLanguageTag = 'en'});
  final String initialLanguageTag;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()),
        ChangeNotifierProvider(create: (_) => LocaleNotifier(initialLanguageTag: initialLanguageTag)),
      ],
      child: Consumer<LocaleNotifier>(
        builder: (context, localeNotifier, _) {
          return MaterialApp(
            title: 'All-in-One Games',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.numberLinkTheme,
            locale: localeNotifier.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('zh', 'TW'),
              Locale('zh', 'CN'),
              Locale('es'),
              Locale('fr'),
              Locale('it'),
              Locale('sv'),
              Locale('de'),
              Locale('ja'),
              Locale('ko'),
              Locale('pt'),
              Locale('ru'),
              Locale('nl'),
              Locale('pl'),
              Locale('tr'),
              Locale('ar'),
              Locale('hi'),
              Locale('th'),
              Locale('vi'),
              Locale('id'),
              Locale('el'),
              Locale('cs'),
              Locale('ro'),
              Locale('hu'),
              Locale('da'),
              Locale('no'),
              Locale('fi'),
            ],
            initialRoute: AppRouter.home,
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
