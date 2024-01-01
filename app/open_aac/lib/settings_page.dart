import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings Page
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
            SizedBox(height: 20),
            TextFormField(
              controller: pineconeKeyController,
              decoration: InputDecoration(
                labelText: 'Pinecone Api Key',
                contentPadding: EdgeInsets.only(bottom: 1.0)),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: pineconeEnvController,
              decoration: InputDecoration(
                labelText: 'Pinecone Environment',
                contentPadding: EdgeInsets.only(bottom: 1.0)),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: pineconeProjectIdController,
              decoration: InputDecoration(
                labelText: 'Pinecone Project ID',
                contentPadding: EdgeInsets.only(bottom: 1.0)),
            ),
            SizedBox(height: 20),
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