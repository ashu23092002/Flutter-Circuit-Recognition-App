import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
      
  if (kIsWeb) {
    runApp(MainApp(displayText: 'Web World'));
  } else if(Platform.isAndroid){
    final cameras = await availableCameras();
    runApp(
      MaterialApp(
        home:CameraApp(
          cameras: cameras,
        ),
      )
    );
  } else {
    runApp(MainApp(displayText: 'Desktop World'));
  }
}

/// Android Camera App
class CameraApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  /// Camera App Initialization
  const CameraApp({super.key, required this.cameras});


  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraApp> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera(_currentCameraIndex);
  }

  /// Initialize camera based on index
  void _initializeCamera(int cameraIndex) {
    _controller = CameraController(
      widget.cameras[cameraIndex],
      ResolutionPreset.max,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  /// Switch camera
  void _switchCamera() {
    setState(() {
      _currentCameraIndex = (_currentCameraIndex + 1) % widget.cameras.length;
      _initializeCamera(_currentCameraIndex);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera App'),),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture, 
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child:CircularProgressIndicator());
          }
        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 10,
        children: [
          /// Take Picture
          FloatingActionButton(
            heroTag: 'take_picture',
            onPressed: () async {
              try {
                await _initializeControllerFuture;
                final image = await _controller.takePicture();
                if(!mounted) {
                  return;
                }
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => DisplayPictureScreen(imagePath: image.path),
                ));
              } catch(e) {
                print(e);
              }
            },
            child: Builder(
              builder: (context) {
                double iconSize = MediaQuery.of(context).size.width * 0.1;
                return Icon(
                  Icons.camera,
                  size: iconSize,
                );
              }
            )
          ),
          /// Switch Camera
          FloatingActionButton(
            onPressed: _switchCamera,
            heroTag: 'switch_camera',
            child: Builder(
              builder: (context) {
                double iconSize = MediaQuery.of(context).size.width * 0.1;
                return Icon(
                  Icons.switch_camera_outlined,
                  size: iconSize,
                );
              }
            )
          ),
        ]
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  ///Display Last Picture
  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Last Picture'),),
      body: Center(child: Image.file(File(imagePath)),),
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