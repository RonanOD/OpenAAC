import 'package:langchain_openai/langchain_openai.dart' show OpenAIEmbeddings;
import 'package:pinecone/pinecone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:string_validator/string_validator.dart';

const String modelName = 'text-embedding-ada-002';
const String pcIndex   = 'openaac-embeddings';
const String namespace = 'openaac-images';
const String blankTilePath = 'images/_app/blank.png';

// Config Map
var config = { };

class Mapping {
  final String word;
  final String imagePath;
  final bool poorMatch;

  Mapping(this.word, this.imagePath, this.poorMatch);
}

// Perform a lookup on the current text using the AI engine
Future<List<Mapping>> lookup(String text) async {
  List<Mapping> mappings = [];
  if (text.isNotEmpty && await checkConfig()) {
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
      if (word.isEmpty || word == '' || !isAlphanumeric(word)) {
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
        if (match.score! < 0.92) {
          print("poor match for $word");
          mapping = Mapping(word, blankTilePath, true);
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

// Check the config map for the required keys
Future<bool> checkConfig() async {
  if (config.isEmpty) {
    // Load config from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    config['openAIApiKey']      = prefs.getString('openAIKey');
    config['pineconeApiKey']    = prefs.getString('pineconeKey');
    config['pineconeEnv']       = prefs.getString('pineconeEnv');
    config['pineconeProjectID'] = prefs.getString('pineconeProjectID');
  }
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