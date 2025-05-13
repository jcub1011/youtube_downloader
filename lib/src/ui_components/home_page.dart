import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/main.dart';
import 'package:youtube_downloader/src/ui_components/download_list.dart';
import 'package:youtube_downloader/src/ui_components/download_overview_page.dart';
import 'package:filepicker_windows/filepicker_windows.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState createState() {
    return _HomePageState();
  }
}

// https://coolors.co/000000-14213d-fca311-e5e5e5-ffffff
// http://coolors.co/dce0d9-31081f-6b0f1a-595959-808f85
// https://coolors.co/122c34-224870-2a4494-4ea5d9-44cfcb
class _HomePageState extends ConsumerState<HomePage> {
  String? sourceUrl;
  final TextEditingController _sourceUrlController = TextEditingController();
  final DownloadListView _downloadListView = const DownloadListView();
  final DownloadOverviewPage _downloadOverviewPage = const DownloadOverviewPage();

  retrieveDownloadInfo() {
    setState(() {
      sourceUrl = _sourceUrlController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122C34),
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
      body: Column(
        children: [
          const DownloadLocationSelector(),
          UrlEntrySpot(sourceUrlController: _sourceUrlController),
          const SizedBox(height: 24),
          const Text(
            "Download List",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              TextButton(
                child: const Text('Select All'),
                onPressed: () {  
                  ref.read(downloadListProvider.notifier).setAllDownloadItemSelections(true);
                  log("All items selected.");
                }
              ),
              TextButton(
                child: const Text('Deselect All'),
                onPressed: () {  
                  ref.read(downloadListProvider.notifier).setAllDownloadItemSelections(false);
                  log("All items deselected.");
                }
              ),
              TextButton(
                onPressed: () {
                  ref.read(downloadProgressProvider.notifier).setDownloadProgressTargets(ref.read(downloadListProvider), ref.read(downloadLocationProvider));
                },
                child: const Text(
                  "Download Selected",
                  style: TextStyle(
                    color: Color(0xFF44CFCB),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(child: _downloadListView),
                const SizedBox(width: 12),
                Expanded(child: _downloadOverviewPage),
                const SizedBox(width: 12)
              ],
            ),
          ),
          const SizedBox(height: 12)
          ],
        ),
      );
  }
}

class UrlEntrySpot extends ConsumerWidget {
  const UrlEntrySpot({super.key, required this.sourceUrlController});
  final TextEditingController sourceUrlController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextFormField(
              controller: sourceUrlController,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
              ),
              decoration: const InputDecoration(
                labelText: 'Enter URL here...', 
                labelStyle: TextStyle(
                  color: Color(0xFF44CFCB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.search),
            color: const Color(0xFF44CFCB),
            onPressed: () {
              log("URL: ${sourceUrlController.text}");
              ref.read(downloadListProvider.notifier)
                .setDownloadSource(sourceUrlController.text);
            }
          ),
        ],
      ),
    );
  }
}

class DownloadLocationSelector extends ConsumerWidget {
  const DownloadLocationSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        TextButton(
          child: const Text('Select Download Location'),
          onPressed: () {
            var directorySelector = DirectoryPicker()..title = "Select Download Location";
            var directory = directorySelector.getDirectory();
        
            if (directory == null) {
              log("No directory selected");
              return;
            }
        
            ref.read(downloadLocationProvider.notifier).state = directory.path;
            log("Download location set to: ${directory.path}");
          },
        ),
        const SizedBox(width: 12),
        Text(ref.watch(downloadLocationProvider)),
      ],
    );
  }
}