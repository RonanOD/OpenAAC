import 'package:cli/cli.dart' as cli;
import 'dart:io' show Platform, sleep;
import 'package:langchain_openai/langchain_openai.dart' show OpenAIEmbeddings;
import 'package:langchain/langchain.dart' show Document;
import 'package:pinecone/pinecone.dart';

// The main() function is the entry point of the application
// Run the application with: dart bin/cli.dart <path>
// Process adapted from Python and this tutorial: https://docs.pinecone.io/docs/langchain
void main(List<String> arguments) {
  if (arguments.length != 1) {
    print('Usage: cli <path>');
    return;
  }

  print('Utility to load images in ${arguments[0]} to embeddings database');
  List<String> images = cli.getImages(arguments[0]);

  // Initialize variables
  final modelName = 'text-embedding-ada-002';
  final pcIndex = 'openaac-embeddings';

  // Get OPENAI_API_KEY from environment variable: https://help.openai.com/en/articles/4936850-where-do-i-find-my-api-key
  final openAIApiKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIApiKey == null) {
    print('OPENAI_API_KEY environment variable not set');
    return;
  }

  // Get PINECONE_API_KEY from environment variable: https://docs.pinecone.io/docs/projects#api-keys
  final pineconeApiKey = Platform.environment['PINECONE_API_KEY'];
  if (pineconeApiKey == null) {
    print('PINECONE_API_KEY environment variable not set');
    return;
  }

  // Get PINECONE_ENV from environment variable: https://docs.pinecone.io/docs/projects#project-environment
  final pineconeEnv = Platform.environment['PINECONE_ENV'];
  if (pineconeEnv == null) {
    print('PINECONE_ENV environment variable not set');
    return;
  }

  // Get PINECONE_PROJECT_ID from environment variable: https://docs.pinecone.io/docs/projects#project-id
  final pineconeProjectID = Platform.environment['PINECONE_PROJECT_ID'];
  if (pineconeProjectID == null) {
    print('PINECONE_PROJECT_ID environment variable not set');
    return;
  }

  // Create Pinecone client
  PineconeClient pcClient = PineconeClient(
    apiKey: pineconeApiKey,
  );

  // Create OpenAIEmbeddings client
  final openAIEmbeddings = OpenAIEmbeddings(
    apiKey: openAIApiKey,
    model: modelName,
  );

  List<Document> documents = cli.populateDocuments(images);
  
  cli.convertDocumentsToEmbeddings(documents, openAIEmbeddings).then((docEmbeddings) { 
      if (docEmbeddings.length != documents.length) {
        print('Error: ${docEmbeddings.length} embeddings returned for ${documents.length} documents');
        return;
      }
      cli.checkPineConeIndex(pcClient, pineconeEnv, pcIndex, docEmbeddings).then((indexes) {
        if (indexes.contains(pcIndex)) {
          print('Index $pcIndex already exists');
          cli.upsertEmbeddings(pcClient, pineconeEnv, pcIndex, pineconeProjectID, documents, docEmbeddings).then((response) {
              print('Upsert response: $response');
          });
        } else {
          print('Creating index $pcIndex');
          pcClient.createIndex(
              environment: pineconeEnv,
              request: CreateIndexRequest(name: pcIndex, dimension: docEmbeddings.first.length, metric: SearchMetric.cosine,
            ),
          ).then((response) {
            // Pause a few seconds to allow the index to be created
            sleep(Duration(seconds: 5));
            cli.upsertEmbeddings(pcClient, pineconeEnv, pcIndex, pineconeProjectID, documents, docEmbeddings).then((response) {
              print('Upsert response: $response');
            });
          });
        }
      }
    );
  });
}
