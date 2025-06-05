import 'dart:convert';

import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:citystat1/l10n/l10n.dart';
import 'package:citystat1/src/binding.dart';
import 'package:citystat1/src/constants.dart';
import 'package:citystat1/src/db/secure_storage.dart';
import 'package:citystat1/src/model/account/home_preferences.dart';
import 'package:citystat1/src/model/account/home_widgets.dart';
import 'package:citystat1/src/model/analysis/analysis_preferences.dart';
import 'package:citystat1/src/model/auth/auth_session.dart';
import 'package:citystat1/src/model/auth/session_storage.dart';
import 'package:citystat1/src/model/broadcast/broadcast_preferences.dart';
import 'package:citystat1/src/model/notifications/notification_service.dart';
import 'package:citystat1/src/model/notifications/notifications.dart';
import 'package:citystat1/src/model/settings/board_preferences.dart';
import 'package:citystat1/src/model/settings/preferences_storage.dart';
import 'package:citystat1/src/model/study/study_preferences.dart';
import 'package:citystat1/src/utils/chessboard.dart';
import 'package:citystat1/src/utils/color_palette.dart';
import 'package:citystat1/src/utils/screen.dart';
import 'package:citystat1/src/utils/string.dart';
import 'package:logging/logging.dart';
import 'package:material_color_utilities/palettes/core_palette.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

final _logger = Logger('Init');

/// Run initialization tasks only once on first app launch or after an update.
Future<void> setupFirstLaunch() async {
//?Goal: Run one-time tasks the first time the app is opened or when the app is updated.
 //?This includes:
    //? Wiping old sensitive data
    //? Generating identifiers
    //? Initializing preferences
    //? Migrating user data between versions
 
  final prefs = CitystatBinding.instance.sharedPreferences; //? app's local key-value store (like SharedPreferences).
  final pInfo = await PackageInfo.fromPlatform(); //?The version name from pubspec.yaml.
  final appVersion = Version.parse(pInfo.version);
  final installedVersion = prefs.getString('installed_version'); //?What version was saved the last time this app ran.

  if (prefs.getBool('first_run') ?? true) {
    // Clear secure storage on first run because it is not deleted on app uninstall
    await SecureStorage.instance.deleteAll();

    // Generate a socket random identifier and store it for the app lifetime
    final sri = genRandomString(12); //? Generate a Random SRI (Socket Random Identifier)
    _logger.info('Generated new SRI: $sri');
    await SecureStorage.instance.write(key: kSRIStorageKey, value: sri);

    // on android 12+ set board theme to system colors
    if (getCorePalette() != null) {
      final boardPrefs = BoardPrefs.defaults.copyWith(boardTheme: BoardTheme.system);
      await prefs.setString(PrefCategory.board.storageKey, jsonEncode(boardPrefs.toJson()));
    }

    _screenSizeBasedInitialization();

    await prefs.setBool('first_run', false);
  }


//?Data Migration for Older App Versions
  if (installedVersion != null && Version.parse(installedVersion) < Version(0, 15, 12)) {
    // migrate home preferences to session preferences
    final homePrefs = prefs.getString(PrefCategory.home.storageKey);
    if (homePrefs == null) {
      final storedSession = await SecureStorage.instance.read(key: kSessionStorageKey);
      final session = storedSession != null
          ? AuthSessionState.fromJson(jsonDecode(storedSession) as Map<String, dynamic>)
          : null;
      const empty = HomePrefs(disabledWidgets: IListConst<HomeEditableWidget>([]));
      // keep quick game matrix for already installed apps, since it was removed by default in 0.15.12
      prefs.setString(
        SessionPreferencesStorage.key(PrefCategory.home.storageKey, session),
        jsonEncode(empty.toJson()),
      );
    } else {
      prefs.setString(SessionPreferencesStorage.key(PrefCategory.home.storageKey, null), homePrefs);
    }
  }

  if (installedVersion == null || Version.parse(installedVersion) != appVersion) {
    prefs.setString('installed_version', appVersion.canonicalizedVersion);
  }
}



Future<void> initializeLocalNotifications(Locale locale) async {
  final l10n = await AppLocalizations.delegate.load(locale); //? Loads localized strings (usually from .arb files) for the provided locale.
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final initializationSettings = InitializationSettings(
    android: const AndroidInitializationSettings('logo_black'),
    iOS: DarwinInitializationSettings(
      requestBadgePermission: false,
      notificationCategories: <DarwinNotificationCategory>[
        ChallengeNotification.darwinPlayableVariantCategory(l10n),
        ChallengeNotification.darwinUnplayableVariantCategory(l10n),
      ],
    ),
    linux: LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    ),
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: NotificationService.onDidReceiveNotificationResponse,
  );
}

// Future<void> initializeLocalNotifications(Locale locale) async {
//   final l10n = await AppLocalizations.delegate.load(locale);
//   await FlutterLocalNotificationsPlugin().initialize(
//     InitializationSettings(
//       android: const AndroidInitializationSettings('logo_black'),
//       iOS: DarwinInitializationSettings(
//         requestBadgePermission: false,
//         notificationCategories: <DarwinNotificationCategory>[
//           ChallengeNotification.darwinPlayableVariantCategory(l10n),
//           ChallengeNotification.darwinUnplayableVariantCategory(l10n),
//         ],
//       ),
//     ),
//     onDidReceiveNotificationResponse: NotificationService.onDidReceiveNotificationResponse,
//     // onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
//   );
// }

Future<void> preloadPieceImages() async {
  final prefs = CitystatBinding.instance.sharedPreferences; //?This retrieves the already-loaded shared preferences object from your singleton (CitystatBinding).
    print("prefs");
    print(prefs.toString());
  final storedPrefs = prefs.getString(PrefCategory.board.storageKey);
      print("storedPrefs");
  print(storedPrefs.toString());
  BoardPrefs boardPrefs = BoardPrefs.defaults;
  if (storedPrefs != null) { //?Checks whether any preferences were saved before:
    try {
      boardPrefs = BoardPrefs.fromJson(jsonDecode(storedPrefs) as Map<String, dynamic>); //? tries to decode the saved JSON string into a Dart map.Converts the map into a BoardPrefs object using a fromJson constructor.
    } catch (e) {
      _logger.warning('Failed to decode board preferences: $e');
    }
  }

  await precachePieceImages(boardPrefs.pieceSet); //? It uses the final boardPrefs.pieceSet value to preload the piece images into memory/cache.
}

/// Display setup on Android.
///
/// This is meant to be called once during app initialization.
Future<void> androidDisplayInitialization(WidgetsBinding widgetsBinding) async {
  // On android 12+ set dynamic color schemes
  try {
    Future.wait([DynamicColorPlugin.getCorePalette(), DynamicColorPlugin.getColorSchemes()]).then((
      List<dynamic> value,
    ) {
      final CorePalette? palette = value[0] as CorePalette?;
      final schemes = value[1] as dynamic;
      final ColorSchemes? colorSchemes = schemes != null
          // ignore: avoid_dynamic_calls
          ? (light: schemes.light as ColorScheme, dark: schemes.dark as ColorScheme)
          : null;

      setSystemColors(palette, colorSchemes);
    });
  } catch (e) {
    _logger.fine('Device does not support core palette: $e');
  }

  // lock orientation to portrait on android phones
  final view = widgetsBinding.platformDispatcher.views.first;
  final data = MediaQueryData.fromView(view);
  if (data.size.shortestSide < FormFactor.tablet) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // Sets edge-to-edge system UI mode on Android 12+
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: true,
    ),
  );

  /// Enables high refresh rate for devices where it was previously disabled
  final List<DisplayMode> supported = await FlutterDisplayMode.supported;
  final DisplayMode active = await FlutterDisplayMode.active;

  final List<DisplayMode> sameResolution =
      supported
          .where((DisplayMode m) => m.width == active.width && m.height == active.height)
          .toList()
        ..sort((DisplayMode a, DisplayMode b) => b.refreshRate.compareTo(a.refreshRate));

  final DisplayMode mostOptimalMode = sameResolution.isNotEmpty ? sameResolution.first : active;

  // This setting is per session.
  await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
}

// Adjusts some settings for small screens based on the MediaQuery data.
Future<void> _screenSizeBasedInitialization() async {
  final prefs = CitystatBinding.instance.sharedPreferences;
  final mediaQueryData = MediaQueryData.fromView(
    WidgetsBinding.instance.platformDispatcher.views.first,
  );
  final isSmallScreen = estimateHeightMinusBoard(mediaQueryData) < kSmallHeightMinusBoard;

  final analysisPrefs = AnalysisPrefs.defaults.copyWith(showEngineLines: !isSmallScreen);
  await prefs.setString(PrefCategory.analysis.storageKey, jsonEncode(analysisPrefs.toJson()));
  final studyPrefs = StudyPrefs.defaults.copyWith(showEngineLines: !isSmallScreen);
  await prefs.setString(PrefCategory.study.storageKey, jsonEncode(studyPrefs.toJson()));
  final broadcastPrefs = BroadcastPrefs.defaults.copyWith(showEngineLines: !isSmallScreen);
  await prefs.setString(PrefCategory.broadcast.storageKey, jsonEncode(broadcastPrefs.toJson()));
}
