import 'dart:io';

List<String> getImages(String path) {
  final dir = Directory(path);
  List<String> files = [];
  
  List contents = dir.listSync();
  for (var fileOrDir in contents) {
    if (fileOrDir is File) {
      files.add(fileOrDir.path);
    } 
  }

  return files;
}
