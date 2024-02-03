import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:openaac/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ai.dart' as ai;

const String imageCachePrefix = "images/";

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _usernameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _openAIController = TextEditingController();

  var _loading = true;

  @override
  void initState() {
    super.initState();
    _getProfile();
    _loadPreferences();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _websiteController.dispose();
    _openAIController.dispose();
    super.dispose();
  }

  /// Called once a user id is received within `onAuthenticated()`
  Future<void> _getProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      final data =
          await supabase.from('profiles').select().eq('id', userId).single();
      _usernameController.text = (data['username'] ?? '') as String;
      _websiteController.text = (data['website'] ?? '') as String;
    } on PostgrestException catch (error) {
      SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (error) {
      SnackBar(
        content: const Text('Unexpected error occurred'),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Called when user taps `Update` button
  Future<void> _updateProfile() async {
    setState(() {
      _loading = true;
    });
    final userName = _usernameController.text.trim();
    final website = _websiteController.text.trim();
    final user = supabase.auth.currentUser;
    final updates = {
      'id': user!.id,
      'username': userName,
      'website': website,
      'updated_at': DateTime.now().toIso8601String(),
    };
    try {
      await supabase.from('profiles').upsert(updates);
      if (mounted) {
        const SnackBar(
          content: Text('Successfully updated profile!'),
        );
      }
    } on PostgrestException catch (error) {
      SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (error) {
      SnackBar(
        content: const Text('Unexpected error occurred'),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (error) {
      SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (error) {
      SnackBar(
        content: const Text('Unexpected error occurred'),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _openAIController.text = prefs.getString('openAIKey') ?? '';
  }

  _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('openAIKey', _openAIController.text);
    // Reset the config map
    ai.config = { };
  }

  _clearImagesCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith(imageCachePrefix)) {
        prefs.remove(key);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'User Name'),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(labelText: 'Website'),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _loading ? null : _updateProfile,
                  child: Text(_loading ? 'Saving...' : 'Update'),
                ),
                const SizedBox(height: 18),
                TextButton(onPressed: _signOut, child: const Text('Sign Out')),
                const SizedBox(height: 20),
                SizedBox(
                  child: Text('Images Cache',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _clearImagesCache();
                  },
                  child: Text('Clear Cache'),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _openAIController,
                  decoration: InputDecoration(
                    labelText: 'OpenAI Api Key',
                    contentPadding: EdgeInsets.only(bottom: 1.0)),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _savePreferences();
                  },
                  child: Text('Save'),
                ),
              ],
            ),
    );
  }
}
