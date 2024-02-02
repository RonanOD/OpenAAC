import 'dart:convert';
import 'dart:typed_data';

import 'package:langchain_openai/langchain_openai.dart' show OpenAIEmbeddings;
import 'package:pinecone/pinecone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:image/image.dart' as img;

const String modelName = 'text-embedding-ada-002';
const String pcIndex   = 'openaac-embeddings';
const String namespace = 'openaac-images';
const String blankTilePath = 'images/_app/blank.png';
const String imageGenPrompt = '''
Create a simplified image of "XXXX", created only using primary colors 
on a white background. The design should be minimalistic with no additional 
details or text. This image should resemble the stylistic approach of icons 
utilized in an AAC (Augmentative and Alternative Communication) application.''';
const double vectorMatchThreshold = 0.92;
const String imageGenModel = "dall-e-3";
const String imageCachePrefix = "images/";

// Config Map
var config = { };

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

  if (text.isNotEmpty && await _checkConfig()) {
    // Access Supabase client
    final sbClient = Supabase.instance.client;

    print("text to lookup: $text");
    // Split the text into a list of words
    List<String> words = text.split(' ');
    for (var word in words) {
      word = word.replaceAll(RegExp(r"[^A-Za-z0-9']"), ""); // Strip out anything not alphanumeric preserving apostrophes
      if (word.isEmpty || word == '') {
        continue;
      }
      
      final response = await sbClient.functions.invoke(
        "getImages", 
        body: {'words': word},
        headers: {'Authorization': "Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}",
          'Content-Type': 'application/json'}
      );

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
            mapping = Mapping(word, imagePath, false);
          }
        } else {
          print("No match for $word. Attempting image generation.");
          mapping = await _generateImage(word);
        }
        mappings.add(mapping);
      }
      //TODO: Add error messaging
    }
  }
  return mappings;
}

// Perform a lookup on the current text using Pinecone
Future<List<Mapping>> lookupPinecone(String text) async {
  List<Mapping> mappings = [];
  if (text.isNotEmpty && await _checkConfig()) {
    // Create Pinecone client
    PineconeClient pcClient = PineconeClient(
      apiKey: config['pineconeApiKey']!,
    );

    // Create OpenAIEmbeddings client
    OpenAIEmbeddings openAIEmbeddings = OpenAIEmbeddings(
      apiKey: config['openAIApiKey']!,
      model: modelName,
    );
    print("text to lookup: $text");
    // Split the text into a list of words
    List<String> words = text.split(' ');
    for (var word in words) {
      word = word.replaceAll(RegExp(r"[^A-Za-z0-9']"), ""); // Strip out anything not alphanumeric preserving apostrophes
      if (word.isEmpty || word == '') {
        continue;
      }
      var embedding = await openAIEmbeddings.embedQuery(word);
      var response =  await pcClient.queryVectors(
          environment: config['pineconeEnv']!,
          projectId: config['pineconeProjectID']!,
          indexName: pcIndex,
          request: QueryRequest(
            includeMetadata: true,
            namespace: namespace,
            vector: embedding,
            topK: 1,
            includeValues: false,
          ),
        );
      if (response.matches.isNotEmpty) {
        VectorMatch match = response.matches[0];
        Mapping mapping;
        if (match.score! < vectorMatchThreshold) {
          print("poor match for $word. Attempting image generation.");
          mapping = await _generateImage(word);
        } else {
          var imagePath = match.metadata!['path'];
          print("word $word => $imagePath");
          mapping = Mapping(word, imagePath, false);
        }
        mappings.add(mapping);
      }
    }
  }
  return mappings;
}

// Use OpenAI to generate an image as there isn't a close enough pinecone match.
// Cache generated images in local storage to keep costs down
Future<Mapping> _generateImage(String word) async {
  Mapping mapping;
  String? b64Json;
  String cacheKey = imageCachePrefix + word;

  // Check Shared Preferences for cached image data
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final cachedB64Json = prefs.getString(cacheKey);

  if (cachedB64Json == null) { // Call out to OpenAI to generate the image
    String prompt = imageGenPrompt.replaceAll('XXXX', word);

    final image = await OpenAI.instance.image.create(
      prompt: prompt,
      model: imageGenModel,
      n: 1,
      style: OpenAIImageStyle.vivid,
      size: OpenAIImageSize.size1024,
      responseFormat: OpenAIImageResponseFormat.b64Json,
    );
    
    // Copy resized image file to memory
    final imageData = image.data[0];
    b64Json = imageData.b64Json;
    
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

// Check the config map for the required keys
Future<bool> _checkConfig() async {
  if (config.isEmpty) {
    // Load config from shared preferences and check for required keys
    SharedPreferences prefs = await SharedPreferences.getInstance();
    config['openAIApiKey']  = prefs.getString('openAIKey');
    // TODO: Move DALLE-gen to Edge function
    if (config['openAIApiKey'] == null) {
      print('OPENAI_API_KEY environment variable not set');
      return false;
    }

    // Set the OpenAI API key for image generation
    OpenAI.apiKey = config['openAIApiKey']!;
  }

  return true;
}