import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ShowFile extends StatelessWidget {
  const ShowFile({Key? key, this.file}) : super(key: key);
  final File? file;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Image.file(file!)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          saveImage();
        },
      ),
    );
  }

  Future<void> saveImage() async {
   
    await  getExternalStorageDirectories().then((value) {
      print(value!.first.path);
      final fileName = basename(file!.path);
      print(fileName);
      print('${value.first.path}/$fileName');
      file!.copy('${value.first.path}/$fileName');
    });
  }
}
