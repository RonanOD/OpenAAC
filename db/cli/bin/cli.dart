import 'package:cli/cli.dart' as cli;
import 'package:args/args.dart' show ArgParser;

const String path = 'path';
const String test = 'test';

// The main() function is the entry point of the application
// Run the application with: dart bin/cli.dart <path>
// Process adapted from Python and this tutorial: https://docs.pinecone.io/docs/langchain
void main(List<String> args) async {
  var parser = ArgParser();
  parser.addOption(path, abbr: 'p', help: 'Path to images to upload to Pinecone');
  parser.addFlag(test,   abbr: 't', help: 'Input strings to test embeddings');

  var inputs = parser.parse(args);

  if (inputs[path] != null) {
    print('Loading images from folder: ${inputs[path]}');
    cli.loadImages(inputs[path]);
  } else if (inputs[test] == true) {
    print('Testing embeddings');
    cli.runTextTest();
  } else {
    print('Utility to load and test images in an embeddings database');
    print(parser.usage);
  }
}
