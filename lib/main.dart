
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    providerWeb: kDebugMode
        ? WebDebugProvider()
        : ReCaptchaV3Provider('6Le0FSkuAAAAACyhJ1PZZ2Y4Mb7xc8X20cZU5CwL'),

    providerAndroid: const AndroidDebugProvider(),
    providerApple: const AppleDebugProvider(),
  );

  runApp(const LifeLensApp());
}
