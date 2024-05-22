import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:openaac/main.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _redirecting = false;
  late final TextEditingController _emailController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;

  Future<void> _signIn() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        emailRedirectTo:
            kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your email for a login link!')),
        );
        _emailController.clear();
      }
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _signInAnon() async {
    try {
      setState(() {
        _isLoading = true;
      });
        _redirecting = true;
        Navigator.of(context).pushReplacementNamed('/home');
    } catch (error) {
      SnackBar(
        content: const Text('Unexpected error occurred'),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      if (_redirecting) return;
      final session = data.session;
      if (data.event == AuthChangeEvent.signedIn) {

        await FirebaseMessaging.instance.requestPermission();
        // Handle potential getAPNSToken() error
        try { 
          await FirebaseMessaging.instance.getAPNSToken(); 

          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            _setFCMToken(fcmToken);
          }
        } on PlatformException catch (e) {
          // Handle the error (e.g., log, display message)
          print('Error getting APNS token: $e');
        }  
      }
      if (session != null) {
        _redirecting = true;
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) { 
      _setFCMToken(fcmToken);
    });

    FirebaseMessaging.onMessage.listen((payload) {
      final notification = payload.notification;
      if (notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${notification.title} ${notification.body}')));
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login to Learningo (Optional)"),
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
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          const Text('Sign in via the magic link with your email below'),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            child: Text(_isLoading ? 'Loading' : 'Send Magic Link'),
          ),
          const SizedBox(height: 18),
          const Text('Use without providing email'),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isLoading ? null : _signInAnon,
            child: Text(_isLoading ? 'Loading' : 'Sign in Anonymously'),
          ),
        ],
      ),
    );
  }

  void _launchSite() async {
   final Uri url = Uri.parse('https://learningo.org/app');
   if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
    }
  }

  Future<void> _setFCMToken(String fcmToken) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      await supabase.from('profiles').upsert({
        'id': userId,
        'fcm_token': fcmToken,
      });
    }
  }
}
