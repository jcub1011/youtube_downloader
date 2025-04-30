import 'dart:developer';
import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';

import 'package:flutter/material.dart';
import 'package:youtube_downloader/src/ui_components/download_list.dart';
//import 'package:youtube_downloader/src/ui_components/home_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// https://coolors.co/000000-14213d-fca311-e5e5e5-ffffff
// http://coolors.co/dce0d9-31081f-6b0f1a-595959-808f85
// https://coolors.co/122c34-224870-2a4494-4ea5d9-44cfcb
class _HomePageState extends State<HomePage> {
  String? sourceUrl;
  final TextEditingController _sourceUrlController = TextEditingController();
  final DownloadListView _downloadListView = const DownloadListView();

  retrieveDownloadInfo() {
    setState(() {
      sourceUrl = _sourceUrlController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF122C34)
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
            child: Column(
              children: [
                Row(
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
                            color: Color(0xFF224870),
                          )
                        ),
                        filled: false,
                        
                        // Placeholder text
                        labelText: 'Enter URL here...', 
                        labelStyle: const TextStyle(
                          color: Color(0xFF44CFCB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                    )
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.search),
                    color: const Color(0xFF44CFCB),
                    onPressed: () {
                      log("URL: ${_sourceUrlController.text}");
                      
                    }
                  ),
                 ]
                ),
                const SizedBox(height: 24),
                const Text(
                  "Download List",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _downloadListView,
              ],
            ),
          ),
        )
      ),
    );
  }
}