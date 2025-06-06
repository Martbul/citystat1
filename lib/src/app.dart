import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n_esperanto/l10n_esperanto.dart';
import 'package:citystat1/l10n/l10n.dart';
import 'package:citystat1/src/app_links.dart';
import 'package:citystat1/src/model/account/account_repository.dart';
import 'package:citystat1/src/model/account/account_service.dart';
import 'package:citystat1/src/model/challenge/challenge_service.dart';
import 'package:citystat1/src/model/common/preloaded_data.dart';
import 'package:citystat1/src/model/correspondence/correspondence_service.dart';
import 'package:citystat1/src/model/notifications/notification_service.dart';
import 'package:citystat1/src/model/settings/board_preferences.dart';
import 'package:citystat1/src/model/settings/general_preferences.dart';
import 'package:citystat1/src/network/connectivity.dart';
import 'package:citystat1/src/network/socket.dart';
import 'package:citystat1/src/tab_scaffold.dart';
import 'package:citystat1/src/theme.dart';
import 'package:citystat1/src/utils/navigation.dart';
import 'package:citystat1/src/utils/screen.dart';

/// Application initialization and main entry point.
/// 

//?AppInitializationScreen – Purpose
//?This widget serves as the transition layer between startup logic and your app's UI. It waits for preloadedDataProvider to complete loading your initial data (config, preferences, assets, etc.), then:
   //? Removes the native splash screen (FlutterNativeSplash.remove())
  //?  Launches the app (Application())
  //?  Shows nothing while waiting
   //? Handles errors gracefully
class AppInitializationScreen extends ConsumerWidget {
  const AppInitializationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<PreloadedData>>(preloadedDataProvider, (_, state) { //?This listens to state changes of the preloadedDataProvider. It does two things: On success or failure, it removes the native splash screenEnsures the splash screen only disappears when data is fully preloaded or failed (prevents early removal)
      if (state.hasValue || state.hasError) {
        FlutterNativeSplash.remove();
      }
    });

    return ref
        .watch(preloadedDataProvider)
        .when(
          data: (_) => const Application(),
          // loading screen is handled by the native splash screen
          loading: () => const SizedBox.shrink(),
          error: (err, st) {
            debugPrint('SEVERE: [App] could not initialize app; $err\n$st');
            return const SizedBox.shrink();
          },
        );
  }
}

/// The main application widget.
///
/// This widget is the root of the application and is responsible for setting up
/// the theme, locale, and other global settings.
//? This is the  app scaffold—everything up to this point was preloading and setup.

//? ConsumerStatefulWidget is a Riverpod-specific class that extends Flutter’s StatefulWidget. It creates a mutable state(via _AppState and injects the Riverpod ref object)
class Application extends ConsumerStatefulWidget {
  const Application({super.key}); //?constructor
   @override
  ConsumerState<Application> createState() => _AppState(); //?Creating a stateful widgets with Riverpod
  //? here the retrn trype is ConsumerState<Application>, meaning that the method must return an instance of a class that extends ConsumerState<Application>
  //? super.key passes the optional key from the Application constructor to its parent class
  //?Why it matters:Keys help Flutter identify widgets during rebuilds.Ensures smooth animations, efficient UI updates.
 
  /* 
  ?   In stateful widgets, Flutter needs a way to instantiate the State object that will:
   ? Hold the widget's mutable state
    ?Handle lifecycle events (initState, dispose, etc.)
    ?Provide the build method
?So every StatefulWidget or ConsumerStatefulWidget must implement:
?In your case:
?   The widget class is Application
 ?   The state class is _AppState 
 */
  
}
/*
?This class is not a function. But it does have important functions inside it that Flutter automatically calls at the right time:
?Method	Called When?	What it Does
?initState()	When widget is first inserted in the tree	Initializes services, listeners
?build(context)	When widget needs to draw itself	Returns the actual UI (widget)
?So you’re not calling _AppState() like a function. Instead, Flutter creates an instance 
?of _AppState internally and calls its build() method, which returns the actual widget.

*/
class _AppState extends ConsumerState<Application> {
  /// Whether the app has checked for online status for the first time.
  bool _firstTimeOnlineCheck = false;


//?Starting Services
  @override
  void initState() {
    // Start services
    ref.read(notificationServiceProvider).start(); //?Starts the notification service.
    ref.read(challengeServiceProvider).start();
    ref.read(accountServiceProvider).start();
    ref.read(correspondenceServiceProvider).start();


/*
?This sets up a manual listener to watch for changes in internet connectivity and app lifecycle state.
?connectivityChangesProvider is likely a stream provider or notifier that emits online/offline changes.
?You get both prev and current values, allowing you to detect state transitions (e.g., from offline to online).
*/
    // Listen for connectivity changes and perform actions accordingly.
    ref.listenManual(connectivityChangesProvider, (prev, current) async {
      final prevWasOffline = prev?.value?.isOnline == false;
      final currentIsOnline = current.value?.isOnline == true;

      // Play registered moves whenever the app comes back online.
      if (prevWasOffline && currentIsOnline) {
        final nbMovesPlayed = await ref.read(correspondenceServiceProvider).playRegisteredMoves();
        if (nbMovesPlayed > 0) {
          ref.invalidate(ongoingGamesProvider);
        }
      }

      // Perform actions once when the app comes online.
      if (current.value?.isOnline == true && !_firstTimeOnlineCheck) {
        _firstTimeOnlineCheck = true;
        ref.read(correspondenceServiceProvider).syncGames();
      }

      final socketClient = ref.read(socketPoolProvider).currentClient;
      if (current.value?.isOnline == true &&
          current.value?.appState == AppLifecycleState.resumed &&
          !socketClient.isActive) {
        socketClient.connect();
      } else if (current.value?.isOnline == false) {
        socketClient.close();
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final generalPrefs = ref.watch(generalPreferencesProvider);
    final boardPrefs = ref.watch(boardPreferencesProvider);
    final theme = makeAppTheme(context, generalPrefs, boardPrefs);

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MaterialLocalizationsEo.delegate,
        CupertinoLocalizationsEo.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      title: 'CityStat',
      locale: generalPrefs.locale,
      theme: theme.copyWith(
        navigationBarTheme: isIOS
            ? null
            : NavigationBarTheme.of(
                context,
              ).copyWith(height: isShortVerticalScreen(context) ? 60 : null),
      ),
      onGenerateRoute: (settings) =>
          settings.name != null ? resolveAppLinkUri(context, Uri.parse(settings.name!)) : null,
      onGenerateInitialRoutes: (initialRoute) {
        final homeRoute = buildScreenRoute<void>(context, screen: const MainTabScaffold());
        return <Route<dynamic>?>[
          homeRoute,
          resolveAppLinkUri(context, Uri.parse(initialRoute)),
        ].nonNulls.toList(growable: false);
      },
      navigatorObservers: [rootNavPageRouteObserver],
    );
  }
}
