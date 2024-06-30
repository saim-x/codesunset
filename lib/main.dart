
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'pages/home_page.dart'; // Corrected import path
import 'package:supabase_flutter/supabase_flutter.dart';
Future <void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://azetyotwyucstbuajylf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF6ZXR5b3R3eXVjc3RidWFqeWxmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTk3NTgwNDMsImV4cCI6MjAzNTMzNDA0M30.66poyfm7DCBJejFbxDcC6oavLwxaUwspP4v8lhv3new',
  );
  runApp(const MyApp());
}
final supabase = Supabase.instance.client;
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saims App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF101720),
        appBarTheme: AppBarTheme(
          backgroundColor:
              const Color(0xFF101720), // Set the background color for AppBar
          foregroundColor:
              Colors.white, // Set the color for the AppBar's text and icons
        ),
      ),
      home: const HomePage(),
    );
  }
}