import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'android_app.dart';
import 'default_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
      
  if (kIsWeb) {
    runApp(
      MaterialApp(
        home: MainApp(displayText: 'Web App')
      ),
    );
  } else if(Platform.isAndroid){
    runApp(
      MaterialApp(
        home:CameraApp(),
      )
    );
  } else {
    runApp(
      MaterialApp(
        home: MainApp(displayText: 'Desktop App')
      ),
    );
  }
}
