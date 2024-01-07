import 'package:flutter/material.dart';
import 'package:open_aac/settings_page.dart';
import 'package:provider/provider.dart';

import 'ai.dart' as ai;
import 'tts.dart' as tts;

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
  final tts.AppTts appTts = tts.AppTts();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    textController.dispose();
    appTts.stop();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    appTts.initTts();
  }

  void _onTileClicked(String word){
    //debugPrint("You tapped on item $word");
    appTts.flutterTts.speak(word);
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
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 164 * ((context.read<AppState>().mappings.length / 2) + 1),
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing:1,
                    runSpacing: 1,
                    direction: Axis.horizontal,
                    children: context.read<AppState>().mappings.map((item) {
                      if (item.poorMatch) {
                        Image overlay = Image.memory(item.generatedImage);
                        Image blank = Image.asset("assets/${ai.blankTilePath}");
                        return InkResponse(
                          onTap: () => _onTileClicked(item.word),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: 
                                  Align(
                                    alignment: Alignment.topCenter,
                                    widthFactor: 2.5,
                                    heightFactor: 1.2,
                                    child: Text(
                                      item.word,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                              ),
                              Positioned(
                                top: 26,
                                width: blank.width,
                                height: blank.height,
                                child: overlay,
                              ),
                              blank, // Blank background has transparency to display above
                            ],
                          ),
                        );
                      } else {
                        return Column(
                          children: [
                            InkResponse(
                              onTap: () => _onTileClicked(item.word),
                              child: Image.asset("assets/${item.imagePath}")
                            ),
                          ],
                        );
                      }
                    },
                  ).toList(),
                ),
              ),
            ),
          ),
          ],
        ),
      );
    }
  }
}
