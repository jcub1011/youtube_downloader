import 'package:flutter/material.dart';
//import 'package:youtube_downloader/src/ui_components/home_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

}

// https://coolors.co/000000-14213d-fca311-e5e5e5-ffffff
class _HomePageState extends State<HomePage> {
  String? sourceUrl;
  final TextEditingController _sourceUrlController = TextEditingController();

  retrieveDownloadInfo() {
    setState(() {
      sourceUrl = _sourceUrlController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 53, 75, 122),
            Color(0xFF14213D),
          ],
          
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "YouTube Downloader",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          
          // Centers the app bar title
          centerTitle: true, 
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ),
            
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
             children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _sourceUrlController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                  ),
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.blueGrey,
                      )
                    ),
                    filled: false,
                    
                    // Placeholder text
                    labelText: 'Enter URL here...', 
                    labelStyle: const TextStyle(
                      color: Color(0xFFE5E5E5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                )
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.search),
                color: Colors.white,
                onPressed: () => {print("button pressed")}
              )
             ]
            ),
          ),
        )
      ),
    );
  }
}