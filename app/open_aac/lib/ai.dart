import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;

const String modelName = 'text-embedding-ada-002';
const String pcIndex   = 'openaac-embeddings';
const String namespace = 'openaac-images';
const String blankTilePath = 'images/_app/blank.png';
const double vectorMatchThreshold = 0.78;
const String genImagesCachePrefix = "images/openai/";
const String storedImagesCachePrefix = "images/supabase/";

class Mapping {
  final String word;
  final bool poorMatch;
  final String? imagePath;
  final Uint8List imageBytes;

  Mapping(this.word, this.imagePath, this.poorMatch, this.imageBytes);
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
        // Attempt to retrieve the image from either generated or storage images cache
        Mapping? mapping = await _getFileFromCaches(word); 

        if (mapping == null) {
          // No cached image; proceed with Supabase query
          final response = await sbClient.functions.invoke("getImages", body: {'words': word});
          print("word $word => Status: ${response.status} Initial: ${response.data}");
          if (response.status == 200) {
            Mapping mapping;
            if (response.data.length > 0) {
              final match = response.data[0];
              final similarity = match['similarity'].toString();
              if (double.parse(similarity) < vectorMatchThreshold) {
                print("poor match for $word. Attempting image generation.");
                mapping = await _generateImage(sbClient, word);
              } else {
                mapping = await _downloadStoredFile(sbClient, match['path'], word);
              }
            } else {
              print("No match for $word. Attempting image generation.");
              mapping = await _generateImage(sbClient, word);
            }
            mappings.add(mapping);
          }
        } else {
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

// Check only for cached files
Future<Mapping?> _getFileFromCaches(String word) async {
  // Build the potential image path for generated image
  final genImagePath = genImagesCachePrefix + word; 

  var genImageCacheFile = await DefaultCacheManager().getFileFromCache(genImagePath);

  if (genImageCacheFile != null) {
    // Cache hit! Construct mapping directly
    return Mapping(word, genImagePath, true, genImageCacheFile.file.readAsBytesSync());
  }

  // Build the potential image path for a stored image
  final storedImagePath = storedImagesCachePrefix + word; 

  var storedImageFile = await DefaultCacheManager().getFileFromCache(storedImagePath);

  if (storedImageFile != null) {
    // Cache hit! Construct mapping directly
    return Mapping(word, storedImagePath, false, storedImageFile.file.readAsBytesSync());
  }

  return null;
}

Future<Mapping> _downloadStoredFile(SupabaseClient client, String remoteImagePath, String word) async {
  try {
    Uint8List? imageBytes = await client.storage.from('images').download(remoteImagePath);
    
    if (imageBytes.isNotEmpty) {
      // Put the image file in the cache for the next time.
      final storedImagePath = storedImagesCachePrefix + word;

      await DefaultCacheManager().putFile(
        storedImagePath,
        imageBytes,
        fileExtension: "png",
        eTag: "real",
        key: storedImagePath,
        maxAge: Duration(days: 50),
      );
      return Mapping(word, storedImagePath, false, imageBytes);
    }
  } on StorageException catch (err) {
    // Not found or some other issue, just return a blank tile
    print("Storage exception: ${err.message}");    
  }
  // blank tile
  return await _getBlankMapping(word);
}

// Use edge function to generate an image as there isn't a close enough vector match.
// Cache generated images in local storage to keep costs down
Future<Mapping> _generateImage(SupabaseClient sbClient, String word) async {
  final imagePath = genImagesCachePrefix + word;
  final response = await sbClient.functions.invoke("generateImage", body: {'word': word});
  String b64Json = response.data;

  final base64Decoder = base64.decoder;
  final decodedBytes = base64Decoder.convert(b64Json);

  Uint8List? resizedData;
  if (decodedBytes.isNotEmpty) {
    img.Image? rawImage = img.decodeImage(decodedBytes);
    img.Image resized = img.copyResize(rawImage!, width: 144, height: 144);
    resizedData = img.encodePng(resized);

    // Cache the generated image 
    await DefaultCacheManager().putFile(imagePath, resizedData, 
      fileExtension: "png", eTag: "generated", key: imagePath, maxAge: Duration(days: 50),
    );
  } 

  if (resizedData != null) {
    return Mapping(word, null, true, resizedData);
  } else {
    return _getBlankMapping(word);
  }
}

Future<Mapping> _getBlankMapping(String word) async {
  final blankImageData = await rootBundle.load(blankTilePath);
  return Mapping(word, blankTilePath, true, blankImageData.buffer.asUint8List());
}
