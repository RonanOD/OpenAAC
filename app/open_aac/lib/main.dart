
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
           actions: <Widget>[
             IconButton(
               icon: const Icon(Icons.settings),
               tooltip: 'App settings',
               onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SecondRoute()),
                );
              },
             ),
           ],
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

/// Second Route Class
class SecondRoute extends StatefulWidget {
  @override
  _SecondRouteState createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController openAIController = TextEditingController();
  TextEditingController pineconeKeyController = TextEditingController();
  TextEditingController pineconeEnvController = TextEditingController();
  TextEditingController pineconeProjectIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    openAIController.text = prefs.getString('openAIKey') ?? '';
    pineconeKeyController.text = prefs.getString('pineconeKey') ?? '';
    pineconeEnvController.text = prefs.getString('pineconeEnv') ?? '';
    pineconeProjectIdController.text = prefs.getString('pineconeProjectID') ?? '';
  }

  _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('openAIKey', openAIController.text);
    prefs.setString('pineconeKey', pineconeKeyController.text);
    prefs.setString('pineconeEnv', pineconeEnvController.text);
    prefs.setString('pineconeProjectID', pineconeProjectIdController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: openAIController,
              decoration: InputDecoration(
                labelText: 'OpenAI Api Key',
                contentPadding: EdgeInsets.only(bottom: 1.0)),
            ),
            TextFormField(
              controller: pineconeKeyController,
              decoration: InputDecoration(
                labelText: 'Pinecone Api Key',
                contentPadding: EdgeInsets.only(bottom: 1.0)),
            ),
            TextFormField(
              controller: pineconeEnvController,
              decoration: InputDecoration(
                labelText: 'Pinecone Environment',
                contentPadding: EdgeInsets.only(bottom: 1.0)),
            ),
            TextFormField(
              controller: pineconeProjectIdController,
              decoration: InputDecoration(
                labelText: 'Pinecone Project ID',
                contentPadding: EdgeInsets.only(bottom: 1.0)),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Go Back'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _savePreferences();
                  },
                  child: Text('Save'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}