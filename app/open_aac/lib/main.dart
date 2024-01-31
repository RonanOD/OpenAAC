import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:openaac/pages/splash_page.dart';
import 'package:openaac/pages/login_page.dart';
import 'package:openaac/pages/account_page.dart';

const publicAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJwY3hleGhydWRrdHlya2tla25lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDU4NDEwODgsImV4cCI6MjAyMTQxNzA4OH0.zr7v1hbvkSBfz7wLTVU7J2g3NUAwAmLgHNuNdG7jULw';
const supabaseURL   = 'https://bpcxexhrudktyrkkekne.supabase.co';

final supabase = Supabase.instance.client;

void main() async {  
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseURL,
    anonKey: publicAnonKey,
  );
  runApp(OpenAAC());
}

class OpenAAC extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learningo Open AAC',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.green,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
          ),
        ),
      ),

      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/account': (_) => const AccountPage(),
      },
    );
  }
}


