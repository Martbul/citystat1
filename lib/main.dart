
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citystat1/src/app.dart';
import 'package:citystat1/src/binding.dart';
import 'package:citystat1/src/init.dart';
import 'package:citystat1/src/intl.dart';
import 'package:citystat1/src/log.dart';
import 'package:citystat1/src/model/common/service/sound_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  // Widgets is a framework and this is the "glue" to bind the framework to the Flutter engine
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

 // 🧱 Initialize sqflite for Linux
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final citystatBinding = AppCityStatBinding.ensureInitialized();

  // Show splash screen until app is ready
  // See src/app.dart for splash screen removal
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding); //?This tells Flutter to keep showing the splash screen (defined in native Android/iOS code) until we explicitly remove it later in the app. It's part of the flutter_native_splash package.

  await citystatBinding.preloadSharedPreferences();

  await preloadPieceImages();

  await setupFirstLaunch();

  await SoundService.initialize();

//? setups localization
  final locale = await setupIntl(widgetsBinding);

  await initializeLocalNotifications(locale);

  await citystatBinding.initializeFirebase();

   // Initialize Firebase for supported platforms
  // if (!kIsWeb && (Platform.isAndroid ||
  //         Platform.isIOS ||
  //         Platform.isMacOS ||
  //         Platform.isWindows ||
  //         Platform.isLinux)) {
  //           print("FIREBASE LAUNCHING");
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  // }
  

  if (defaultTargetPlatform == TargetPlatform.android) {
    await androidDisplayInitialization(widgetsBinding);
  }

//? the ENTRY POINT
  runApp(
    ProviderScope(
      observers: 
      [ProviderLogger()],
       child: const AppInitializationScreen()
)
);
}

//? runApp(...) is the Flutter entry point that inflates the widget tree and starts rendering the UI.

//? ProviderScope(...) - This comes from Riverpod — a state management library. ProviderScope:Wraps your entire app.
//?Manages the lifecycle of providers (like dependency injection or global state).
//?Allows reading/watching providers anywhere down the tree.Think of this as setting up a context for Riverpod to work in.

//?observers: [ProviderLogger()]

//? child: const AppInitializationScreen() This is the first visible screen of your app.
//? shows a splash screen, loading animation, or performs final checks before entering the main app 



