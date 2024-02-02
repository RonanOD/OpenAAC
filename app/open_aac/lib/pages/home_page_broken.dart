import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:openaac/pages/settings_page.dart';
import 'package:openaac/ai.dart' as ai;
import 'package:openaac/tts.dart' as tts;

/* PREVIOUS build method in main.dart
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Open AAC',
        home: HomePage(title: 'Open AAC'),
      ),
    );
  }
 */

class AppState extends ChangeNotifier {
  List<ai.Mapping> mappings = [];
  bool isLoading = false;

  void checkText(var text) {
    ai.lookupPinecone(text).then((mappings) {
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

class HomePageBroke extends StatefulWidget {
  const HomePageBroke({super.key, required this.title});

  final String title;

  @override
  _HomePageBrokeState createState() => _HomePageBrokeState();
}

class _HomePageBrokeState extends State<HomePageBroke> {
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
    appTts.flutterTts.speak(word);
  }

  @override
  Widget build(BuildContext context) {
      return ChangeNotifierProvider(
      create: (context) => AppState(),
      builder: _buildHome(context, this),
    );
  }
  
  _buildHome(BuildContext context, child) {
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
                  IconButton(
                    icon: const Icon(Icons.record_voice_over),
                    onPressed: () {
                      if (textController.text.isNotEmpty) {
                        appTts.flutterTts.speak(textController.text);
                      }
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
