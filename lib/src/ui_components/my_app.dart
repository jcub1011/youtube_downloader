import 'package:flutter/material.dart';
import 'package:youtube_downloader/src/ui_components/home_page.dart';

class DownloaderApp extends StatelessWidget {
  const DownloaderApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true, 

      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              "Video Downloader",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
            bottom: const TabBar(
              tabs: [
                Tab(text: "Configuration"),
                Tab(text: "Download Selections"),
                Tab(text: "Download Progress"),
                Tab(text: "Errors"),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              ConfigurationPage(),
              DownloadSelectionView(),
              Center(child: Text("Download Progress")),
              Center(child: Text("Errors")),
            ],
          ),
        ),
      ),

      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color.fromARGB(255, 159, 75, 49),
      ),
    );
  }
}