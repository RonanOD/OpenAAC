import 'package:cli/cli.dart' as cli;
import 'dart:io' show Platform;
import 'package:langchain_openai/langchain_openai.dart' show OpenAIEmbeddings;
import 'package:langchain/langchain.dart' show Document;

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

  // Get OPENAI_API_KEY from environment variable
  final openAIApiKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIApiKey == null) {
    print('OPENAI_API_KEY environment variable not set');
    return;
  }

  // Get PINECONE_API_KEY from environment variable
  final pineconeApiKey = Platform.environment['PINECONE_API_KEY'];
  if (pineconeApiKey == null) {
    print('PINECONE_API_KEY environment variable not set');
    return;
  }

  // Initialize OpenAIEmbeddings
  final modelName = 'text-embedding-ada-002';
  final openAIEmbeddings = OpenAIEmbeddings(
    apiKey: openAIApiKey,
    model: modelName,
  );
  
  // Convert all png images in the directory into OpenAI embeddings documents. 
  // The file name is the text (word) and the full path is the metadata.
  final List<Document> documents = [];
  // use RegExp to grab the file name without the path
  final RegExp regex = RegExp(r'[^/]*$');

  for (var image in images) {
    if (image.endsWith('.png')) {
      final String fileName = regex.stringMatch(image)!;
      if (fileName != '') {
        documents.add(Document(pageContent: fileName, metadata: {'path': image}));
      }
    }
    print(documents);
  }

  openAIEmbeddings.embedDocuments(documents);
}
