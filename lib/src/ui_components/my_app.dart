import 'dart:ui';

import 'package:flutter/material.dart';

import '../entities/video_retriever.dart';
import 'configuration_page.dart';
import 'download_list.dart';
import 'download_overview_page.dart';

// https://coolors.co/000000-14213d-fca311-e5e5e5-ffffff
// http://coolors.co/dce0d9-31081f-6b0f1a-595959-808f85
// https://coolors.co/122c34-224870-2a4494-4ea5d9-44cfcb

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
                color: Colors.cyanAccent,
              ),
            ),
            bottom: const TabBar(
              dividerHeight: 0,
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
        scaffoldBackgroundColor: const Color.fromARGB(255, 43, 58, 103),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(0, 0, 0, 0),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Color.fromARGB(255, 0, 157, 220),
          labelStyle: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 78, 165, 217),
            fontWeight: FontWeight.w600,
          ),
          indicatorColor: Color.fromARGB(255, 78, 165, 217),
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Color.fromARGB(255, 78, 165, 217),
          hoverColor: Color.fromARGB(255, 99, 124, 201),
          textTheme: ButtonTextTheme.primary,
        ),
      ),
    );
  }
}