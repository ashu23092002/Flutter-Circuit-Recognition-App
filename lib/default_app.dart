import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:circuit_recognition_app/display_picture_screen.dart';

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
            FloatingActionButton(
              heroTag: 'spice_simulator',
              onPressed: () {},
              child: IconTheme(
                data: IconThemeData(size: 40.0), 
                child: const Icon(Icons.settings_input_composite),
              ),
            ),
          ]
        ),
      ),
    );
  }
}