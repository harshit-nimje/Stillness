import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/stillness_app.dart';
import 'data/stillness_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge, transparent system bars — no Android chrome contradicting
  // the Stillness design.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  final data = await StillnessStore.load();
  runApp(StillnessApp(data: data));
}
