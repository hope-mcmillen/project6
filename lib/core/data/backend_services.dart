import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../ai/ai_service.dart';
import '../ai/daily_ai_allowance.dart';
import '../ai/fake_ai_service.dart';
import '../ai/firebase_ai_service.dart';
import '../ai/firebase_json_client.dart';
import 'app_check_mode.dart';
import 'fake_repositories.dart';
import 'firestore_repositories.dart';
import 'repositories.dart';

/// Member 4 creates one bundle at startup and injects it into feature screens.
class BackendServices {
  const BackendServices({
    required this.closet,
    required this.outfits,
    required this.profile,
    required this.wearLogs,
    required this.ai,
  });
  final ClosetRepository closet;
  final OutfitRepository outfits;
  final ProfileRepository profile;
  final WearLogRepository wearLogs;
  final AiService ai;

  factory BackendServices.fake({bool withSampleCloset = false}) =>
      BackendServices(
        closet: FakeClosetRepository(
          items: withSampleCloset ? sampleCloset() : [],
        ),
        outfits: FakeOutfitRepository(),
        profile: FakeProfileRepository(),
        wearLogs: FakeWearLogRepository(),
        ai: FakeAiService(),
      );

  /// Firebase configuration must come from the team's real FlutterFire setup.
  /// Call only once at startup, before accessing Firestore anywhere else.
  static Future<BackendServices> connect({
    required FirebaseOptions options,
    String modelName = 'gemini-3.5-flash-lite',
    int dailyAiLimit = DailyAiAllowance.defaultLimit,
    AppCheckMode? appCheck,
  }) async {
    final app = await Firebase.initializeApp(options: options);
    // New AI Logic projects enforce App Check during provider setup.
    // Debug tokens stay local and must be authorized in the Firebase console.
    // Set --dart-define=APP_CHECK=debug for builds not installed from Play.
    final mode = appCheck ?? appCheckModeFor(debugBuild: kDebugMode);
    await FirebaseAppCheck.instanceFor(
      app: app,
    ).activate(providerAndroid: androidAppCheckProvider(mode));
    final auth = FirebaseAuth.instanceFor(app: app);
    final user = await ensureAnonymousSignIn(auth);
    final firestore = FirebaseFirestore.instanceFor(app: app);
    firestore.settings = const Settings(persistenceEnabled: true);
    final scope = UserFirestore(firestore: firestore, uid: user.uid);
    final allowance = await DailyAiAllowance.forDevice(limit: dailyAiLimit);
    return BackendServices(
      closet: FirestoreClosetRepository(scope),
      outfits: FirestoreOutfitRepository(scope),
      profile: FirestoreProfileRepository(scope),
      wearLogs: FirestoreWearLogRepository(scope),
      ai: FirebaseAiService(
        client: DailyLimitedAiJsonClient(
          allowance: allowance,
          client: FirebaseJsonClient(
            firebaseAI: FirebaseAI.googleAI(app: app),
            modelName: modelName,
          ),
        ),
      ),
    );
  }
}
