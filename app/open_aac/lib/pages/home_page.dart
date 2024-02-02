import 'package:flutter/material.dart';
import 'package:openaac/pages/account_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:openaac/ai.dart' as ai;
import 'package:openaac/tts.dart' as tts;

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  // Create a text controller and use it to retrieve the current value
  // of the TextField.
  final textController = TextEditingController();
  final tts.AppTts appTts = tts.AppTts();
  List<ai.Mapping> mappings = [];

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

  void _checkText(var text) {
    ai.lookupSupabase(text).then((mappings) {
      this.mappings = mappings;
      setState(() {
        _isLoading = false;
      });
    }).onError((error, stackTrace) {
      print(error);
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Learningo Open AAC"),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Image.asset('assets/images/_app/logo.png'),
              onPressed: () { _launchSite(); },
              tooltip: "Open Learningo Homepage",
            );
          },
        ),
      ),
      body: _buildHome(context,)
    );
  }

  Widget? _buildHome(BuildContext context) {
    if (_isLoading) {
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
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AccountPage()),
                  );
                },
              ),
            ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            _checkText(textController.text);
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
                      setState(() {
                        _isLoading = true;
                      });
                      _checkText(textController.text);
                    },
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _isLoading = false;
                    });
                    _checkText("");
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
                  height: 164 * ((mappings.length / 2) + 1),
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing:1,
                    runSpacing: 1,
                    direction: Axis.horizontal,
                    children: mappings.map((item) {
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

  void _launchSite() async {
    final Uri url = Uri.parse('https://learningo.org');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}