import 'package:flutter/material.dart';
import 'package:openaac/pages/account_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:openaac/ai.dart' as ai;
import 'package:openaac/tts.dart' as tts;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
  Map<String, Future<List<ai.Mapping>>> _ongoingLookups = {}; // Track in-progress text lookups

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

  void _checkText(var text, BuildContext context) {
    lookupSupabase(text).then((mappings) {
      this.mappings = mappings;
      setState(() {
        _isLoading = false;
      });
    }).onError((error, stackTrace) {
      setState(() {
        _isLoading = false;
      });

      if (error is FunctionException) {
        if (error.reasonPhrase!.toLowerCase().contains('unauthorized')) {
          _dialogBuilder(context, "User not allowed. Contact your administrator.");
        } else {
          final msg = "Error: ${error.reasonPhrase}";
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg ?? "An unknown error occurred")
          ));
        }
      }
    });
  }

  // lookupSupabase with In-Progress Call and Caching
  Future<List<ai.Mapping>> lookupSupabase(String text) async {
    if (_ongoingLookups.containsKey(text)) {
      // Lookup already in progress. Wait for existing future  
      return _ongoingLookups[text]!;  
    }

    // Cache for subsequent calls 
    var lookupFuture = Future(() => ai.lookupSupabase(text)); 
    _ongoingLookups[text] = lookupFuture;

    try {
      // Store and return the result once completed
      var result = await lookupFuture;
      return result; 
    } finally {
      // Ensure we remove it from the ongoing lookups map
      _ongoingLookups.remove(text);
    }
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
        ]
      ),
      body: _buildHome(context,)
    );
  }

  Widget? _buildHome(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            _checkText(textController.text, context);
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
                      _checkText(textController.text, context);
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
                    textController.clear();
                    _checkText("", context);
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
                        Image overlay = Image.memory(item.imageBytes);
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
                              child: Image.memory(item.imageBytes),
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
    final Uri url = Uri.parse('https://learningo.org/app');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _dialogBuilder(BuildContext context, String msg) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notice'),
          content: Text(msg),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
}