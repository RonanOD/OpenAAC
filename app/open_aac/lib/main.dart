
import 'package:flutter/material.dart';
import 'package:open_aac/settings_page.dart';
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
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  List<ai.Mapping> mappings = [];
  bool isLoading = false;

  void checkText(var text) {
    ai.lookup(text).then((mappings) {
      this.mappings = mappings;
      this.isLoading = false;
      notifyListeners();
    }).onError((error, stackTrace) {
      print(error);
      this.isLoading = false;
      notifyListeners();
    });
  }

  void setLoading(bool isLoading) {
    this.isLoading = isLoading;
    notifyListeners();
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

    if (appState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'App settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
              ),
            ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            appState.setLoading(true);
            appState.checkText(textController.text);
          },
          tooltip: 'Convert text to icons',
          child: Icon(Icons.search),
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
                    onSubmitted: (text) {
                      appState.setLoading(true);
                      appState.checkText(text);
                    },
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    appState.setLoading(false);
                    textController.clear();
                    appState.checkText("");
                  },
                  tooltip: 'Clear',
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
}

