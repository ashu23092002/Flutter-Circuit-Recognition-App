import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:circuit_recognition_app/android_app.dart';
import 'package:circuit_recognition_app/default_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
      
  if (kIsWeb) {
    runApp(
      MaterialApp(
        home: MainApp(displayText: 'Web App')
      ),
    );
  } else if(Platform.isAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    final cameras = await availableCameras();
    runApp(
      MaterialApp(
        home:CameraApp(
          cameras: cameras
        ),
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
