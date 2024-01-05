import 'dart:io';
import 'dart:convert';
import 'package:langchain/langchain.dart' show Document;
import 'package:langchain_openai/langchain_openai.dart' show OpenAIEmbeddings;
import 'package:pinecone/pinecone.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:image/image.dart' as img;

// Constants
const String modelName = 'text-embedding-ada-002';
const String pcIndex   = 'openaac-embeddings';
const String namespace = 'openaac-images';
const String imageGenPrompt = '''
Create a simplified image of "XXXX", created only using primary colors 
on a white background. The design should be minimalistic with no additional 
details or text. This image should resemble the stylistic approach of icons 
utilized in an AAC (Augmentative and Alternative Communication) application.''';
const double vectorMatchThreshold = 0.92;
const String imageGenModel = "dall-e-3";

// Config Map
var config = {
  'openAIApiKey':      Platform.environment['OPENAI_API_KEY'],
  'pineconeApiKey':    Platform.environment['PINECONE_API_KEY'],
  'pineconeEnv':       Platform.environment['PINECONE_ENV'],
  'pineconeProjectID': Platform.environment['PINECONE_PROJECT_ID'],
};

// Run a loop testing the conversion of text to embedding images
void runTextTest() async {
  if (!checkConfig()) {
    return;
  }

  // Create Pinecone client
  PineconeClient pcClient = PineconeClient(
    apiKey: config['pineconeApiKey']!,
  );

  // Create OpenAIEmbeddings client
  OpenAIEmbeddings openAIEmbeddings = OpenAIEmbeddings(
    apiKey: config['openAIApiKey']!,
    model: modelName,
  );

  while(true) {
    print('Enter text to convert to an embedding image. Enter to exit.');
    final text = stdin.readLineSync();
    if (text!.isEmpty) {
      print('No text entered. Exiting.');
      return;
    } else {
      print("text to lookup: $text");
      // Split the text into a list of words
      List<String> words = text.split(' ');
      for (var word in words) {
        word = word.replaceAll(RegExp(r"[^A-Za-z0-9']"), ""); // Strip out anything not alphanumeric
        if (word.isEmpty) continue;
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
        print("word $word => Initial: $response");
        if (response.matches.isNotEmpty) {
          VectorMatch match = response.matches[0];
          if (match.score! < vectorMatchThreshold) {
            print("poor match for $word. Attempting image generation.");
            String prompt = imageGenPrompt.replaceAll('XXXX', word);
            final image = await OpenAI.instance.image.create(
              prompt: prompt,
              model: imageGenModel,
              n: 1,
              size: OpenAIImageSize.size1024,
              responseFormat: OpenAIImageResponseFormat.b64Json,
            );

            // Write image file to disk
            final imageData = image.data[0];
            final base64Decoder = base64.decoder;
            final decodedBytes = base64Decoder.convert(imageData.b64Json ?? '');
            if (decodedBytes.isNotEmpty) {
              img.Image? rawImage = img.decodeImage(decodedBytes);
              img.Image resized = img.copyResize(rawImage!, width: 144, height: 144);
              final resizedData = img.encodeJpg(resized);
              final imageFile = "$word.png";
              var file = await File(imageFile).writeAsBytes(resizedData);
              print("wrote to $file");
            }
          } else {
            var imagePath = match.metadata!['path'];
            print("word $word => $imagePath");
          }
        }
      }
    }
  }
}

// Load images from a directory and upload them to Pinecone
void loadImages(String path) {
  if (!checkConfig()) {
    return;
  }

  // Create Pinecone client
  PineconeClient pcClient = PineconeClient(
    apiKey: config['pineconeApiKey']!,
  );

  // Create OpenAIEmbeddings client
  final openAIEmbeddings = OpenAIEmbeddings(
    apiKey: config['openAIApiKey']!,
    model: modelName,
  );

  List<String> images = getImages(path);

  List<Document> documents = populateDocuments(images);
  
  convertDocumentsToEmbeddings(documents, openAIEmbeddings).then((docEmbeddings) { 
      if (docEmbeddings.length != documents.length) {
        print('Error: ${docEmbeddings.length} embeddings returned for ${documents.length} documents');
        return;
      }
      checkPineConeIndex(pcClient, config['pineconeEnv']!, pcIndex, docEmbeddings).then((indexes) {
        if (indexes.contains(pcIndex)) {
          print('Index $pcIndex already exists');
          upsertEmbeddings(
                pcClient, 
                config['pineconeEnv']!, 
                pcIndex, config['pineconeProjectID']!, 
                documents, 
                docEmbeddings).then((response) {
              print('Upsert response: $response');
          });
        } else {
          print('Creating index $pcIndex');
          pcClient.createIndex(
              environment: config['pineconeEnv']!,
              request: CreateIndexRequest(
                name: pcIndex, 
                dimension: docEmbeddings.first.length, 
                metric: SearchMetric.cosine,
            ),
          ).then((response) {
            // Pause a minute to allow the index to be created
            sleep(Duration(seconds: 60));
            upsertEmbeddings(
                pcClient, 
                config['pineconeEnv']!, 
                pcIndex, 
                config['pineconeProjectID']!, 
                documents, 
                docEmbeddings).then((response) {
              print('Upsert response: $response');
            });
          });
        }
      }
    );
  });
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

  // Set the OpenAI API key for image generation
  OpenAI.apiKey = config['openAIApiKey']!;

  return true;
}

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
      String fileName = regex.stringMatch(image)!;
      if (fileName != '') {
        final String content = fileName.replaceAll('_', ' ').replaceAll('.png', '');
        documents.add(Document(
          pageContent: content, 
          metadata: {
            'path': image,
            'text': content}
          )
        );
        print("Adding $image");
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

  // use RegExp to grab the path without the file name
  final RegExp regexPath = RegExp(r'.*/');
  String path = regexPath.stringMatch(documents[0].metadata['path'])!;

  return pcClient.upsertVectors(
    indexName: pcIndex, 
    projectId: pineconeProjectID, 
    environment: pineconeEnv, 
    request: UpsertRequest(
      namespace: namespace,
        vectors: [
          for (var i = 0; i < docEmbeddings.length; i++)
            Vector(
              id: '$path-$i',
              values: docEmbeddings[i],
              metadata: {
                'path': documents[i].metadata['path'], 
                'text': documents[i].metadata['text'],
              },
            ),
        ],
      )
    );
}

