import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:citystat1/firebase_options.dart';
import 'package:citystat1/src/log.dart';
import 'package:citystat1/src/model/engine/engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A singleton class that provides access to plugins and external APIs.
///
/// Only one instance of this class will be created during the app's lifetime.
/// See [AppCityStatBinding] for the concrete implementation.
///
/// Modeled after the Flutter framework's [WidgetsBinding] class.
///
/// The preferred way to mock or fake a plugin or external API is to create a
/// provider with riverpod because it gives more flexibility and control over
/// the behavior of the fake.
/// However, if the plugin is used in a way that doesn't allow for easy mocking
/// with riverpod, a test binding can be used to provide a fake implementation.
/// 
/// 
/// 

//? Defines an interface for binding(what services and APIs it should expose)
abstract class CitystatBinding {
  CitystatBinding() : assert(_instance == null) {
    initInstance();
  }

  /// The single instance of [CitystatBinding].
  static CitystatBinding get instance => checkInstance(_instance);
  static CitystatBinding? _instance;

  @protected
  @mustCallSuper
  void initInstance() {
    _instance = this;
  }

  static T checkInstance<T extends CitystatBinding>(T? instance) {
    assert(() {
      if (instance == null) {
        throw FlutterError.fromParts([
          ErrorSummary('Lichess binding has not yet been initialized.'),
          ErrorHint(
            'In the app, this is done by the `AppCityStatBinding.ensureInitialized()` call '
            'in the `void main()` method.',
          ),
          ErrorHint(
            'In a test, one can call `TestLichessBinding.ensureInitialized()` as the '
            "first line in the test's `main()` method to initialize the binding.",
          ),
        ]);
      }
      return true;
    }());
    return instance!;
  }

  /// The shared preferences instance. Must be preloaded before use.
  ///
  /// This is a synchronous getter that throws an error if shared preferences
  /// have not yet been initialized.
  SharedPreferencesWithCache get sharedPreferences;

  /// Initialize Firebase.
  ///
  /// This wraps [Firebase.initializeApp].
  ///
  /// This should be called only once before the app starts.
  Future<void> initializeFirebase();

  /// Wraps [FirebaseMessaging.instance].
  FirebaseMessaging get firebaseMessaging;

  /// Wraps [FirebaseCrashlytics.instance].
  FirebaseCrashlytics get firebaseCrashlytics;

  /// Wraps [FirebaseMessaging.onMessage].
  Stream<RemoteMessage> get firebaseMessagingOnMessage;

  /// Wraps [FirebaseMessaging.onMessageOpenedApp].
  Stream<RemoteMessage> get firebaseMessagingOnMessageOpenedApp;

  /// Wraps [FirebaseMessaging.onBackgroundMessage].
  void firebaseMessagingOnBackgroundMessage(BackgroundMessageHandler handler);

  /// The factory to create Stockfish
  StockfishFactory get stockfishFactory;
}

/// A concrete implementation of [CitystatBinding] for the app.
class AppCityStatBinding extends CitystatBinding {
  AppCityStatBinding() {
    setupLogging();
  }

  /// Returns an instance of the binding that implements [CitystatBinding].
  ///
  /// If no binding has yet been initialized, the [AppCityStatBinding] class is
  /// 
  /// used to create and initialize one.
  factory AppCityStatBinding.ensureInitialized() {
    //?Ensure only one instance of AppCityStatBinding is created (i.e., Singleton pattern).
//?Return the same instance every time once initialized.
//?Defer instantiation to another part of the class.
    if (CitystatBinding._instance == null) {
      AppCityStatBinding();
    }
    return CitystatBinding.instance as AppCityStatBinding;
  }

  late Future<SharedPreferencesWithCache> _sharedPreferencesWithCache;
  SharedPreferencesWithCache? _syncSharedPreferencesWithCache;

  @override
  SharedPreferencesWithCache get sharedPreferences {
    if (_syncSharedPreferencesWithCache == null) {
      throw FlutterError.fromParts([
        ErrorSummary('Shared preferences have not yet been preloaded.'),
        ErrorHint(
          'In the app, this is done by the `await AppCityStatBinding.preloadSharedPreferences()` call '
          'in the `Future<void> main()` method.',
        ),
        ErrorHint(
          'In a test, one can call `TestLichessBinding.setInitialSharedPreferencesValues({})` as the '
          "first line in the test's `main()` method.",
        ),
      ]);
    }
    return _syncSharedPreferencesWithCache!;
  }

  /// Preload shared preferences.
  ///
  /// This should be called only once before the app starts. Must be called before
  /// [sharedPreferences] is accessed.
  Future<void> preloadSharedPreferences() async {
    //?Future<SharedPreferencesWithCache> _sharedPreferencesWithCache;
    //?late final SharedPreferencesWithCache _syncSharedPreferencesWithCache;


//! the vars in the func will live(not cleard from the stack) as long as the instance of the class lives
    _sharedPreferencesWithCache = SharedPreferencesWithCache.create( //?Holds the future that starts loading the preferences asynchronously.
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    _syncSharedPreferencesWithCache = await _sharedPreferencesWithCache; //?Holds the resolved, ready-to-use, in-memory preferences object.
  }

  @override
  Future<void> initializeFirebase() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    if (kReleaseMode) {
      FlutterError.onError = firebaseCrashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        if (kDebugMode) {
          return false;
        } else {
          firebaseCrashlytics.recordError(error, stack);
          return true;
        }
      };
    }
  }

  @override
  FirebaseMessaging get firebaseMessaging => FirebaseMessaging.instance;

  @override
  FirebaseCrashlytics get firebaseCrashlytics => FirebaseCrashlytics.instance;

  @override
  void firebaseMessagingOnBackgroundMessage(BackgroundMessageHandler handler) {
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  @override
  Stream<RemoteMessage> get firebaseMessagingOnMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get firebaseMessagingOnMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  StockfishFactory get stockfishFactory => const StockfishFactory();
}
