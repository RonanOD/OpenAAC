import 'dart:convert';
import 'dart:typed_data';

import 'package:langchain_openai/langchain_openai.dart' show OpenAIEmbeddings;
import 'package:pinecone/pinecone.dart';
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

// Perform a lookup on the current text using the AI engine
Future<List<Mapping>> lookup(String text) async {
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

// Use OpenAI to generate an image as there isn't a close enough pinecone match
Future<Mapping> _generateImage(String word) async {
  Mapping mapping;
  String prompt = imageGenPrompt.replaceAll('XXXX', word);

  final image = await OpenAI.instance.image.create(
    prompt: prompt,
    model: imageGenModel,
    n: 1,
    size: OpenAIImageSize.size1024,
    responseFormat: OpenAIImageResponseFormat.b64Json,
  );
  
  // Copy resized image file to memory
  final imageData = image.data[0];
  final base64Decoder = base64.decoder;
  final decodedBytes = base64Decoder.convert(imageData.b64Json ?? '');
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
    config['openAIApiKey']      = prefs.getString('openAIKey');
    config['pineconeApiKey']    = prefs.getString('pineconeKey');
    config['pineconeEnv']       = prefs.getString('pineconeEnv');
    config['pineconeProjectID'] = prefs.getString('pineconeProjectID');
    
    if (config['openAIApiKey'] == null) {
      print('OPENAI_API_KEY environment variable not set');
      return false;
    }

    // Get PINECONE_API_KEY from environment variable: https://docs.pinecone.io/docs/projects#api-keys
    if (config['pineconeApiKey'] == null) {
      print('PINECONE_API_KEY environment variable not set');
      return false;
    }

    // Get PINECONE_ENV from environment variable: https://docs.pinecone.io/docs/projects#project-environment
    if (config['pineconeEnv'] == null) {
      print('PINECONE_ENV environment variable not set');
      return false;
    }

    // Get PINECONE_PROJECT_ID from environment variable: https://docs.pinecone.io/docs/projects#project-id
    if (config['pineconeProjectID'] == null) {
      print('PINECONE_PROJECT_ID environment variable not set');
      return false;
    }

    // Set the OpenAI API key for image generation
    OpenAI.apiKey = config['openAIApiKey']!;
  }

  return true;
}