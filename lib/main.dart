import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: JewteColors.paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const Bootstrap());
}
