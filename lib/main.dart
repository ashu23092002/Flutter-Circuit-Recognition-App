import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
      
  if (kIsWeb) {
    runApp(
      MaterialApp(
        home: MainApp(displayText: 'Web App')
      ),
    );
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
    runApp(
      MaterialApp(
        home: MainApp(displayText: 'Desktop App')
      ),
    );
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

  /// Select Picture
  void _selectPicture() async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if(result != null) {
      String? imagePath = result.files.single.path;
      if(imagePath != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DisplayPictureScreen(
              imagePath: imagePath
            ),
          ),
        );
      }
    }
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
          FloatingActionButton(
            heroTag: 'select_picture',
            onPressed: _selectPicture,
            child: IconTheme(
              data: IconThemeData(size: 40.0), 
              child: const Icon(Icons.folder_open),
            ),
          ),
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
            child: IconTheme(
              data: IconThemeData(size: 40.0),
              child: const Icon(Icons.camera),
            ),
          ),
          /// Switch Camera
          FloatingActionButton(
            onPressed: _switchCamera,
            heroTag: 'switch_camera',
            child: IconTheme(
              data: IconThemeData(size: 40.0),
              child: const Icon(Icons.switch_camera),
            ),
          ),
        ]
      ),
    );
  }
}


/// Default App
class MainApp extends StatefulWidget {
  final String displayText;
  
  /// Show platform
  const MainApp({super.key, required this.displayText});

  @override
  WindowScreenState createState() => WindowScreenState();
}

class WindowScreenState extends State<MainApp> {
  late String displayText;
  
  /// Select Picture
  void _selectPicture(BuildContext context) async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if(result != null) {
      String? imagePath = result.files.single.path;
      if(imagePath != null && mounted) {
        if(context.mounted) {
            Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DisplayPictureScreen(
                imagePath: imagePath
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    displayText = widget.displayText;
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text(displayText),),
        body: Center(
          child: Text(displayText),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 10,
          children: [
            FloatingActionButton(
              heroTag: 'select_picture',
              onPressed: () => _selectPicture(context),
              child: IconTheme(
                data: IconThemeData(size: 40.0),
                child: const Icon(Icons.folder_open),
              ),
            ),
          ]
        ),
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String? imagePath;
  ///Display Last Picture
  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Last Picture'),),
      body: Center(child: Image.file(File(imagePath!)),),
    );
  }
}
