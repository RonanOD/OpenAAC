import 'dart:io';
import 'dart:convert';
import 'package:langchain/langchain.dart' show Document;
import 'package:langchain_openai/langchain_openai.dart' show OpenAIEmbeddings;
import 'package:pinecone/pinecone.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:image/image.dart' as img;
import 'package:supabase/supabase.dart';

// Constants
const String modelName = 'text-embedding-3-small';
const String pcIndex   = 'openaac-embeddings';
const String namespace = 'openaac-images';
const String imageGenPrompt = '''
Create a simplified image that is an icon representing "XXXX".
Use only primary colors on a white background. The design is 
minimalist with no additional detail. Do not use any character or typography on the image.
This image should resemble the stylistic approach of icons utilized in an 
AAC (Augmentative and Alternative Communication) application.''';
const double vectorMatchThreshold = 0.92;
const String imageGenModel = "dall-e-2"; // "dall-e-3" is the deluxe option
const String supabaseImagesTable = 's4y_images';

// Config Map
var config = {
  'openAIApiKey':      Platform.environment['OPENAI_API_KEY'],
  'pineconeApiKey':    Platform.environment['PINECONE_API_KEY'],
  'pineconeEnv':       Platform.environment['PINECONE_ENV'],
  'pineconeProjectID': Platform.environment['PINECONE_PROJECT_ID'],
  'supabaseURL':       Platform.environment['SUPABASE_URL'],
  'supabaseAnonKey':   Platform.environment['SUPABASE_ANON_KEY'],
};

// Run a loop testing the conversion of text to embedding images
void runImageTest(bool pinecone) async {
  if (!checkConfig(pinecone)) {
    return;
  }


  while(true) {
    print('Enter text to generate an image. Enter to exit. (Remember there is a cost)');
    final text = stdin.readLineSync();
    if (text!.isEmpty) {
      print('No text entered. Exiting.');
      return;
    } else {
      print("text to lookup: $text");
      // Split the text into a list of words
      List<String> words = text.split(' ');
      for (var word in words) {
        await generateImage(word);
      }
    }
  }
}

// Run a loop testing the conversion of text to embedding images
void runTextTest(bool pinecone) async {
  PineconeClient? pcClient;
  SupabaseClient? sbClient;

  if (!checkConfig(pinecone)) {
    return;
  }

  if (pinecone) {
    // Create Pinecone client
    pcClient = PineconeClient(
      apiKey: config['pineconeApiKey']!,
    );
  } else {
    sbClient = SupabaseClient(
      config['supabaseURL']!, 
      config['supabaseAnonKey']!
    );
  }

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
      if (pinecone) {
        await processPineconeText(words, openAIEmbeddings, pcClient!);
      } else {
        await processSupabaseText(words, openAIEmbeddings, sbClient!);
      }
    }
  }
}

Future<void> processSupabaseText(List<String> words, OpenAIEmbeddings openAIEmbeddings, SupabaseClient sbClient) async {
  for (var word in words) {
    word = word.replaceAll(RegExp(r"[^A-Za-z0-9']"), ""); // Strip out anything not alphanumeric
    if (word.isEmpty) continue;
    final response = await sbClient.functions.invoke(
      "getImages", 
      body: {'words': word},
      headers: {'Authorization': "Bearer ${config['supabaseAnonKey']}",
        'Content-Type': 'application/json'}
    );
  
    print("word $word => Status: ${response.status} Initial: ${response.data}");
    if (response.status == 200 && response.data.length > 0) {
      final match = response.data[0];
      final similarity = match['similarity'].toString();
      
      if (double.parse(similarity) < vectorMatchThreshold) {
        await generateImage(word);
      } else {
        var imagePath = match['path'];
        print("word $word => $imagePath");
      }
    }
    
  }
  exit(0); // Need explicit exit as Supabase client thread seems to persist
}

Future<void> processPineconeText(List<String> words, OpenAIEmbeddings openAIEmbeddings, PineconeClient pcClient) async {
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
        await generateImage(word);
      } else {
        var imagePath = match.metadata!['path'];
        print("word $word => $imagePath");
      }
    }
  }
}

Future<void> generateImage(String word) async {
  print("Attempting image generation for $word.");
  String prompt = imageGenPrompt.replaceAll('XXXX', word);
  final image = await OpenAI.instance.image.create(
    prompt: prompt,
    model: imageGenModel,
    n: 1,
    size: OpenAIImageSize.size512,
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
}

// Load images from a directory and upload them to Supabase
void loadSupabaseImages(String path) async {
  if (!checkConfig(false)) {
    return;
  }
  
  // Create Supabase Client
  final supabaseClient = SupabaseClient(config['supabaseURL']!, config['supabaseAnonKey']!);

  // Create OpenAIEmbeddings client
  final openAIEmbeddings = OpenAIEmbeddings(
    apiKey: config['openAIApiKey']!,
    model: modelName,
  );

  List<String> images = getImages(path);

  List<Document> documents = populateDocuments(images);
  
  final docEmbeddings = await convertDocumentsToEmbeddings(documents, openAIEmbeddings);

  List<Map<String, dynamic>> imageDocs = [];
  for (var i = 0; i < docEmbeddings.length; i++) {
    Map<String, dynamic> row = {};
    row['content'] = documents[i].metadata['text'];
    row['path'] = documents[i].metadata['path'];
    row['embedding'] = docEmbeddings[i];
    imageDocs.add(row);
  }

  await supabaseClient.from(supabaseImagesTable).insert(imageDocs);
  final count = await supabaseClient.from(supabaseImagesTable).count();

  print("Inserted $count rows.");
  
  exit(0); // Need explicit exit as Supabase client thread seems to persist
}

// Load images from a directory and upload them to Pinecone
void loadPineconeImages(String path) {
  if (!checkConfig(true)) {
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
bool checkConfig(bool pinecone) {
  // Get OPENAI_API_KEY from environment variable: https://help.openai.com/en/articles/4936850-where-do-i-find-my-api-key
  if (config['openAIApiKey'] == null) {
    print('OPENAI_API_KEY environment variable not set');
    return false;
  }

  if (pinecone) {
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
  } else { // Only alternative is Supabase for now
    // Get SUPABASE_URL from environment variable: https://supabase.com/docs/guides/auth/sessions
    if (config['supabaseURL'] == null) {
      print('SUPABASE_URL environment variable not set');
      return false;
    }

    // Get SUPABASE_ANON_KEY from environment variable: https://supabase.com/docs/guides/auth/sessions
    if (config['supabaseAnonKey'] == null) {
      print('SUPABASE_ANON_KEY environment variable not set');
      return false;
    }
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
    if (fileOrDir is File && !fileOrDir.path.contains(".DS_Store")) {
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

// Load images from a directory and upload them to Supabase
void loadSupabaseStorage(String path) async {
  if (!checkConfig(false)) {
    return;
  }
  
  // Create Supabase Client
  final supabaseClient = SupabaseClient(config['supabaseURL']!, config['supabaseAnonKey']!);

  List<String> images = getImages(path);
  print("Got ${images.length} files to process.");
  int count = 0;

  for (var i = 0; i < images.length; i++) {
    print("File: ${images[i]}");
    final imageFile = File(images[i]);
    final String path = await supabaseClient.storage.from('images')
      .upload(images[i], 
      imageFile,
      fileOptions: FileOptions());
    print("Uploaded to images as $path");
    count++;
  }

  print("Inserted $count files.");
  
  exit(0); // Need explicit exit as Supabase client thread seems to persist
}
