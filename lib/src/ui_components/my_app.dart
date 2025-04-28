import 'package:flutter/material.dart';
import 'package:youtube_downloader/src/ui_components/home_page.dart';

class DownloaderApp extends StatelessWidget {
  const DownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true, 

      home: const HomePage(),

      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.transparent,
      ),
    );
  }
}