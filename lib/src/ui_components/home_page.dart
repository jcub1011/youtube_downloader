import 'package:flutter/material.dart';
//import 'package:youtube_downloader/src/ui_components/home_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

}

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
            Color(0xFF4C6663),
            Color(0xFF80CFA9),
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
                      color: Colors.black26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                )
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.search),
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