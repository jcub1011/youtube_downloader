import 'package:flutter/material.dart';
import 'package:youtube_downloader/src/ui_components/home_page.dart';

import 'download_overview_page.dart';

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
                Tab(text: "Download Errors"),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              ConfigurationPage(),
              DownloadSelectionView(),
              DownloadOverviewPage(),
              ErrorPage(),
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