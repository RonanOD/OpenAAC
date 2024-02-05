import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;

const String modelName = 'text-embedding-ada-002';
const String pcIndex   = 'openaac-embeddings';
const String namespace = 'openaac-images';
const String blankTilePath = 'images/_app/blank.png';
const double vectorMatchThreshold = 0.78;
const String imageCachePrefix = "images/";

class Mapping {
  final String word;
  final bool poorMatch;
  Uint8List? _generatedImage;
  String? imagePath;

  Mapping(this.word, this.imagePath, this.poorMatch);

  set generatedImage(Uint8List imageBytes) => _generatedImage = imageBytes;
  Uint8List get generatedImage => _generatedImage!;
}

// Perform a lookup on the current text using Supabase
Future<List<Mapping>> lookupSupabase(String text) async {
  List<Mapping> mappings = [];

  if (text.isNotEmpty) {
    // Access Supabase client
    final sbClient = Supabase.instance.client;

    print("text to lookup: $text");
    // Split the text into a list of words
    List<String> words = text.split(' ');
    for (var word in words) {
      word = word.replaceAll(RegExp(r"[^A-Za-z0-9]"), ""); // Strip out anything not alphanumeric
      if (word.isEmpty || word == '') {
        continue;
      }
      try {
        final response = await sbClient.functions.invoke("getImages", body: {'words': word});
        print("word $word => Status: ${response.status} Initial: ${response.data}");
        if (response.status == 200) {
          Mapping mapping;
          if (response.data.length > 0) {
            final match = response.data[0];
            final similarity = match['similarity'].toString();
            if (double.parse(similarity) < vectorMatchThreshold) {
              print("poor match for $word. Attempting image generation.");
              mapping = await _generateImage(word);
            } else {
              var imagePath = match['path'];
              print("word $word => $imagePath");
              final imageBytes = await sbClient.storage.from('images').download(imagePath);
              /*final tempDir = await getTemporaryDirectory();
              File file = await File('${tempDir.path}/image.png').create();
              file.writeAsBytesSync(imageBytes);
              mapping.imagePath = '${tempDir.path}/image.png';*/
              mapping = Mapping(word, imagePath, false);
              mapping.generatedImage = imageBytes;
            }
          } else {
            print("No match for $word. Attempting image generation.");
            mapping = await _generateImage(word);
          }
          mappings.add(mapping);
        }
      } on FunctionException catch (err) {
        print("Function Exception : ${err.reasonPhrase}");
        rethrow;
      }
    }
  }
  return mappings;
}

// Use edge function to generate an image as there isn't a close enough vector match.
// Cache generated images in local storage to keep costs down
Future<Mapping> _generateImage(String word) async {
  Mapping mapping;
  String? b64Json;
  String cacheKey = imageCachePrefix + word;

  // Access Supabase client
  final sbClient = Supabase.instance.client;

  // Check Shared Preferences for cached image data
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final cachedB64Json = prefs.getString(cacheKey);

  if (cachedB64Json == null) { // Call out to OpenAI to generate the image
    final response = await sbClient.functions.invoke("generateImage", body: {'word': word});
    print("word $word => Status: ${response.status} Initial: ${response.data}");
    
    b64Json = response.data;
    prefs.setString(cacheKey, b64Json!); // Save to cache for future use
  } else {
    b64Json = cachedB64Json;
  }

  final base64Decoder = base64.decoder;
  final decodedBytes = base64Decoder.convert(b64Json);
  if (decodedBytes.isNotEmpty) {
    img.Image? rawImage = img.decodeImage(decodedBytes);
    img.Image resized = img.copyResize(rawImage!, width: 144, height: 144);
    final resizedData = img.encodePng(resized);
    mapping = Mapping(word, null, true);
    mapping.generatedImage = resizedData;
  } else {
    mapping = Mapping(word, blankTilePath, true);
  }

  return mapping;
}
