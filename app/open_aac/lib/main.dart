import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ai.dart' as ai;

void main() {
  runApp(OpenAAC());
}

class OpenAAC extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Open AAC',
        theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          ),
        home: HomePage(title: 'Open AAC'),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  List<ai.Mapping> mappings = [];

  void checkText(var text) {
    ai.lookup(text).then((mappings) {
      this.mappings = mappings;
      notifyListeners();
    });
  }
}

class HomePage extends StatefulWidget {
  HomePage({super.key, required this.title});

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Create a text controller and use it to retrieve the current value
  // of the TextField.
  final textController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    textController.dispose();
    super.dispose();
  }

  int getImageCount() {
    return context.read<AppState>().mappings.length;
  }

  List<Image> getImages() {
    List<Image> images = [];
    for (var mapping in context.read<AppState>().mappings) {
      images.add(Image.asset("assets/${mapping.imagePath}"));
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          appState.checkText(textController.text);
        },
        tooltip: 'Convert text to icons',
        child: Icon(Icons.camera_alt_outlined),
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter text to convert to icons',
                  ),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  textController.clear();
                  appState.checkText("");
                },
                icon: Icon(Icons.clear),
                label: Text('Clear'),
              ),
            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // Adjust number of items in a row
                childAspectRatio: 1, // Adjust aspect ratio
              ),
              itemCount: getImageCount() , // Adjust number of items
              itemBuilder: (context, index) {
                return getImages()[index]; // Adjust index
              },
            ),
          ),
        ],
      ),
    );
  }
}