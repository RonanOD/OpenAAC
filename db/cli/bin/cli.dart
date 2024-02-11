import 'package:cli/cli.dart' as cli;
import 'package:args/args.dart' show ArgParser;

const String pineconePath = 'pinecone_path';
const String testPinecone = 'test_pinecone';
const String supabasePath = 'supabase_path';
const String testSupabase = 'test_supabase';
const String supabaseS3   = 'supabase_S3';
const String testImages   = 'test_images';

// The main() function is the entry point of the application
// Run the application with: dart bin/cli.dart <path>
// Process adapted from Python and this tutorial: https://docs.pinecone.io/docs/langchain
void main(List<String> args) async {
  var parser = ArgParser();
  parser.addOption(pineconePath, abbr: 'p', help: 'Path to images to upload to Pinecone');
  parser.addFlag(testPinecone,   abbr: 'i', help: 'Input strings to test Pinecone embeddings');
  parser.addOption(supabasePath, abbr: 's', help: 'Path to images to upload to Supabase');
  parser.addFlag(testSupabase,   abbr: 'u', help: 'Input strings to test Supabase embeddings');
  parser.addOption(supabaseS3,   abbr: 't', help: 'Path to images to upload to Supabase Storage');
  parser.addFlag(testImages,     abbr: 'g', help: 'Input strings to test image generation');

  var inputs = parser.parse(args);

  if (inputs[pineconePath] != null) {
    print('Loading images to Pinecone from folder: ${inputs[pineconePath]}');
    cli.loadPineconeImages(inputs[pineconePath]);
  } else if (inputs[supabasePath] != null) {
    print('Loading images to Supabase from folder: ${inputs[supabasePath]}');
    cli.loadSupabaseImages(inputs[supabasePath]);
  } else if (inputs[testPinecone] == true) {
    print('Testing Pinecone embeddings');
    cli.runTextTest(true);
  } else if (inputs[testSupabase] == true) {
    print('Testing Supabase embeddings');
    cli.runTextTest(false);
  } else if (inputs[supabaseS3] != null) {
    print('Loading images to Supabase Storage from folder: ${inputs[supabaseS3]}');
    cli.loadSupabaseStorage(inputs[supabaseS3]);
  } else if (inputs[testImages] == true) {
    print('Testing Image Generation');
    cli.runImageTest(false);
  } else {
    print('Utility to load and test images in an embeddings database');
    print(parser.usage);
  }
}
