import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geoedu/common/manager/firebase_notification_manager.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/online_presence_service.dart';
import 'package:geoedu/common/widget/restart_widget.dart';
import 'package:geoedu/languages/dynamic_translations.dart';
import 'package:geoedu/screen/splash_screen/splash_screen.dart';
import 'package:geoedu/utilities/firebase_const.dart';
import 'package:geoedu/utilities/theme_res.dart';
import 'common/service/network_helper/network_helper.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Loggers.success("Handling a background message: ${message.data}");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (Platform.isIOS) {
    FirebaseNotificationManager.instance.showNotification(message);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A single bad record (malformed URL, unexpected null, etc.) can otherwise
  // take down just that one card with an unlabeled gray box that never
  // recovers and doesn't respond to taps — Flutter's release-mode default
  // for a build-time exception is a blank error box with no visible text.
  // Collapsing to nothing is a much less confusing failure for a card in a
  // scrollable row: the list just renders with one fewer item instead of a
  // dead, unexplained gap. Errors are still logged for diagnosis.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    Loggers.error('Widget build error: ${details.exception}');
    return const SizedBox.shrink();
  };

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await GetStorage.init('geoedu');

(await AudioSession.instance)
        .configure(const AudioSessionConfiguration.speech());

    NetworkHelper().initialize();

    // Load Translations
    Get.put(DynamicTranslations());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // IMPORTANT ⚠️
        statusBarIconBrightness: Brightness.light, // Android
        statusBarBrightness: Brightness.dark, // iOS
      ),
    );
    // Run app
    runApp(const RestartWidget(child: MyApp()));
  } catch (e, st) {
    Loggers.error('Fatal crash during app startup $st');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final user = SessionManager.instance.getUser();
    if (user?.id == null) return;

    if (state == AppLifecycleState.detached) {
      // App is being killed — clean up active rooms
      _cleanupActiveRooms(user!.id!);
    }
  }

  Future<void> _cleanupActiveRooms(int userId) async {
    final db = FirebaseFirestore.instance;

    try {
      // Clean up audio room if user is host
      final audioDoc = await db
          .collection(FirebaseConst.audioRooms)
          .doc(userId.toString())
          .get();
      if (audioDoc.exists) {
        await db
            .collection(FirebaseConst.audioRooms)
            .doc(userId.toString())
            .delete();
        Loggers.info('AppLifecycle: Deleted audio room for host $userId');
      }

      // Clean up audio room if user is participant (remove from participant_ids)
      final audioRooms = await db
          .collection(FirebaseConst.audioRooms)
          .where('participant_ids', arrayContains: userId)
          .get();
      for (final doc in audioRooms.docs) {
        await doc.reference.update({
          'participant_ids': FieldValue.arrayRemove([userId]),
          'speaker_ids': FieldValue.arrayRemove([userId]),
          'request_ids': FieldValue.arrayRemove([userId]),
        });
        Loggers.info('AppLifecycle: Removed user $userId from audio room ${doc.id}');
      }

      // Clean up livestream if user is host
      final liveDoc = await db
          .collection(FirebaseConst.liveStreams)
          .doc(userId.toString())
          .get();
      if (liveDoc.exists) {
        await db
            .collection(FirebaseConst.liveStreams)
            .doc(userId.toString())
            .delete();
        Loggers.info('AppLifecycle: Deleted livestream for host $userId');
      }

      // Mark user offline
      OnlinePresenceService.instance.goOffline(userId);
    } catch (e) {
      Loggers.error('AppLifecycle: cleanup error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Gio edu",
      builder: (context, child) => ScrollConfiguration(
          behavior: MyBehavior(),
          child: SafeArea(top: false, bottom: true, child: child!)),
      translations: Get.find<DynamicTranslations>(),
      locale: Locale(SessionManager.instance.getLang()),
      fallbackLocale: Locale(SessionManager.instance.getFallbackLang()),
      themeMode: ThemeMode.light,
      darkTheme: ThemeRes.darkTheme(context),
      theme: ThemeRes.lightTheme(context),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
