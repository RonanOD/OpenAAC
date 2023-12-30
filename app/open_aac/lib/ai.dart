import 'dart:io' show Platform;
import 'package:langchain_openai/langchain_openai.dart' show OpenAIEmbeddings;
import 'package:pinecone/pinecone.dart';

const String modelName = 'text-embedding-ada-002';
const String pcIndex   = 'openaac-embeddings';
const String namespace = 'openaac-images';

// Config Map
var config = {
  'openAIApiKey':      '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', //Platform.environment['OPENAI_API_KEY'],
  'pineconeApiKey':    '7eb7e24b-ce47-4d2d-9736-0b89e47d6c9a', //Platform.environment['PINECONE_API_KEY'],
  'pineconeEnv':       'us-east1-gcp', //Platform.environment['PINECONE_ENV'],
  'pineconeProjectID': '174c7d0', //Platform.environment['PINECONE_PROJECT_ID'],
};

class Mapping {
  final String word;
  final String imagePath;

  Mapping(this.word, this.imagePath);
}

// Perform a lookup on the current text using the AI engine
Future<List<Mapping>> lookup(String text) async {
  List<Mapping> mappings = [];
  if (!text!.isEmpty && checkConfig()) {
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
      if (response.matches!.length > 0) {
        var imagePath = response.matches![0].metadata!['path'];
        print("word $word => $imagePath");
        Mapping mapping = Mapping(word, imagePath);
        mappings.add(mapping);
      }
    }
  }
  return mappings;
}

// Check the config map for the required keys
bool checkConfig() {
  // Get OPENAI_API_KEY from environment variable: https://help.openai.com/en/articles/4936850-where-do-i-find-my-api-key
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

  return true;
}