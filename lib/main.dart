import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
      
  if (kIsWeb) {
    runApp(MainApp(displayText: 'Web World'));
  } else if(Platform.isAndroid){
    _cameras = await availableCameras();
    final rearCamera = _cameras.first;
    runApp(
      CameraApp(
        camera: rearCamera,
      )
      );
  } else {
    runApp(MainApp(displayText: 'Desktop World'));
  }
}

/// Android Camera App
class CameraApp extends StatefulWidget {
  /// Default Constructor
  const CameraApp({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<CameraApp> createState() => _CameraAppState();
}

/// Camera Controller Initialization
class _CameraAppState extends State<CameraApp> {
  late CameraController? controller;
  
  @override
  void initState() {
    super.initState();
    controller = CameraController(_cameras[0], ResolutionPreset.max);
    controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Camera Application'),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: _cameraPreviewWidget(),
              ),
            ),
          ],
        ),
      )
    );
  }

  Widget _cameraPreviewWidget() {
    return CameraPreview(
      controller!,
    );
  }
}

/// Default App
class MainApp extends StatelessWidget {
  final String displayText;
  
  /// Show platform
  const MainApp({super.key, required this.displayText});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(displayText),
        ),
      ),
    );
  }
}