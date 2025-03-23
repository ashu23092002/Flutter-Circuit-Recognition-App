import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:circuit_recognition_app/display_picture_screen.dart';

/// Android Camera App
class CameraApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  /// Camera App Initialization
  CameraApp({super.key, required this.cameras});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraApp> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _currentCameraIndex = 0;
  late List<CameraDescription> cameras = widget.cameras;

  @override
  void initState(){
    super.initState();
    _initializeCamera(_currentCameraIndex);
  }

  // /// Initialize cameras
  // Future<void> _initializeCameras() async {
  //   cameras = await availableCameras();
  //   if (cameras.isNotEmpty) {
  //     _initializeCamera(_currentCameraIndex);
  //   } else {
  //     setState(() {});
  //   }
  // }

  /// Initialize camera based on index
  void _initializeCamera(int cameraIndex) {
    _controller = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.max,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  /// Switch camera
  void _switchCamera() {
    setState(() {
      _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;
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
      body: cameras.isEmpty
      ? const Center(child: Text('No camera available'),)
      : FutureBuilder<void>(
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
