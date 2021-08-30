import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_crop/image_crop.dart';
import 'package:image_cropping/showFile.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum AppState { Select, Crop, Save }

class ImageCropTemplate extends StatefulWidget {
  @override
  _ImageCropTemplateState createState() => new _ImageCropTemplateState();
}

class _ImageCropTemplateState extends State<ImageCropTemplate> {
  final cropKey = GlobalKey<CropState>();
  File? _file;
  File? _sample;
  File? _lastCropped;
  final picker = ImagePicker();
  AppState appState = AppState.Select;
  @override
  void dispose() {
    super.dispose();
    _file?.delete();
    _sample?.delete();
    _lastCropped?.delete();
  }

  @override
  void initState() {
    super.initState();
    final permissionsGranted = ImageCrop.requestPermissions();
  }

  Widget getCenterWidget() {
    if (appState == AppState.Select) {
      return Text(
        "Please select Image to Crop ",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
      );
    } else if (appState == AppState.Crop) {
      return _buildCroppingImage();
    } else {
      return Center(child: Image.file(_lastCropped!));
    }
  }

  IconData getIcon() {
    if (appState == AppState.Select) {
      return Icons.add;
    } else if (appState == AppState.Crop) {
      return Icons.crop;
    } else {
      return Icons.save;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(child: getCenterWidget()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _sample == null ? _openImage() : _cropImage();
        },
        child: Icon(getIcon()),
      ),
      bottomNavigationBar: _sample != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                  onPressed: () {
                    _openImage();
                  },
                  child: Text("Select Other Image")))
          : null,
    );
  }

  Widget _buildCroppingImage() {
    return Crop.file(_sample!, key: cropKey, maximumScale: 10);
  }

  Future<void> _openImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    final file = File(pickedFile!.path);
    final sample = await ImageCrop.sampleImage(
      file: file,
      preferredSize: context.size?.longestSide.ceil(),
    );

    _sample?.delete();
    _file?.delete();

    setState(() {
      _sample = sample;
      _file = file;
      appState = AppState.Crop;
    });
  }

  Future<void> _cropImage() async {
    final scale = cropKey.currentState!.scale;
    final area = cropKey.currentState!.area;
    if (area == null) {
      // cannot crop, widget is not setup
      return;
    }

    // scale up to use maximum possible number of pixels
    // this will sample image in higher resolution to make cropped image larger
    final sample = await ImageCrop.sampleImage(
      file: _file!,
      preferredSize: (2000 / scale).round(),
    );

    final file = await ImageCrop.cropImage(
      file: sample,
      area: area,
    );

    sample.delete();

    _lastCropped?.delete();

    setState(() {
      _lastCropped = file;
      appState = AppState.Save;
    });
    debugPrint('$file');
  }

  Future<void> saveImage() async {
    await getExternalStorageDirectories().then((value) {
      print(value!.first.path);
      final fileName = p.basename(_lastCropped!.path);
      print(fileName);
      print('${value.first.path}/$fileName');
      _lastCropped!.copy('${value.first.path}/$fileName');
    });
  }
}
