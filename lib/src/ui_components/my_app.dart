import 'package:flutter/material.dart';

import 'configuration_page.dart';
import 'download_list.dart';
import 'download_overview_page.dart';

// https://coolors.co/000000-14213d-fca311-e5e5e5-ffffff
// http://coolors.co/dce0d9-31081f-6b0f1a-595959-808f85
// https://coolors.co/122c34-224870-2a4494-4ea5d9-44cfcb
// https://coolors.co/f5dfbb-ac3931-2b3a67-48a9a6-009ddc

class DownloaderApp extends StatelessWidget {
  const DownloaderApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true, 
      home: DefaultTabController(
        length: 3,
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
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              ConfigurationPage(),
              DownloadSelectionView(),
              DownloadOverviewPage(),
            ],
          ),
        ),
      ),

      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color.fromARGB(255, 46, 41, 78),
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
          unselectedLabelColor: Color.fromARGB(255, 27, 153, 139),
          labelStyle: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.w600,
          ),
          indicatorColor: Color.fromARGB(255, 244, 96, 54),
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Color.fromARGB(255, 244, 96, 54),
          hoverColor: Color.fromARGB(150, 244, 96, 54),
          textTheme: ButtonTextTheme.primary,
        ),
        textButtonTheme: const TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
            backgroundColor: WidgetStatePropertyAll<Color>(Color.fromARGB(175, 244, 96, 54)),
            overlayColor: WidgetStatePropertyAll<Color>(Color.fromARGB(255, 244, 96, 54)),
            textStyle: WidgetStatePropertyAll<TextStyle>(
              TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(
            color: Color.fromARGB(255, 244, 96, 54),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(255, 244, 96, 54), width: 2),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(175, 244, 96, 54)),
          ),
        ),
        textTheme: const TextTheme(
          labelLarge: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.normal,
            fontStyle: FontStyle.italic,
          ),
          titleSmall: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
        ),
        iconButtonTheme: const IconButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Color.fromARGB(175, 244, 96, 54)),
            overlayColor: WidgetStatePropertyAll<Color>(Color.fromARGB(255, 244, 96, 54)),
            iconColor: WidgetStatePropertyAll<Color>(Colors.white),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        checkboxTheme: CheckboxThemeData(
          checkColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 244, 96, 54)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
          side: BorderSide.none,
        ),
      ),
    );
  }
}