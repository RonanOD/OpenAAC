import 'dart:io';
import 'package:langchain/langchain.dart' show Document;
import 'package:langchain_openai/langchain_openai.dart' show OpenAIEmbeddings;
import 'package:pinecone/pinecone.dart';

// Get all images in the directory
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

// Populate the documents List with the image data
List<Document> populateDocuments(List<String> images) {
  final List<Document> documents = [];
  // use RegExp to grab the file name without the path
  final RegExp regex = RegExp(r'[^/]*$');

  for (var image in images) {
    if (image.endsWith('.png')) {
      final String fileName = regex.stringMatch(image)!;
      if (fileName != '') {
        documents.add(Document(pageContent: fileName, metadata: {'path': image}));
        print("Adding $fileName");
      }
    }
  }

  return documents;
}

// Convert the documents into OpenAI embeddings
Future<List<List<double>>> convertDocumentsToEmbeddings(List<Document> documents, OpenAIEmbeddings openAIEmbeddings) {
  return openAIEmbeddings.embedDocuments(documents).then((embeddings) { 
      print("Embeddedings for ${embeddings.length} documents");
      return embeddings;
    } 
  ).catchError((error) => print(error));
}

// Check Pinecone Indexes, creating the index if it doesn't exist. Return the projectID.
Future<List<String>> checkPineConeIndex(
    PineconeClient pcClient, 
    String pineconeEnv, 
    String pcIndex, 
    List<List<double>> docEmbeddings) {
  return pcClient.listIndexes(environment: pineconeEnv);
}

// Upsert the vectors into the Pinecone index
Future<UpsertResponse> upsertEmbeddings(
    PineconeClient pcClient, 
    String pineconeEnv, 
    String pcIndex, 
    String pineconeProjectID,
    List<Document> documents, 
    List<List<double>> docEmbeddings,) {
  return pcClient.upsertVectors(
    indexName: pcIndex, 
    projectId: pineconeProjectID, 
    environment: pineconeEnv, 
    request: UpsertRequest(
      namespace: "openaac-images",
        vectors: [
          for (var i = 0; i < docEmbeddings.length; i++)
            Vector(
              id: 'img-$i',
              values: docEmbeddings[i],
              metadata: {'path': documents[i].metadata['path']},
            ),
      ],
    )
  );
}

