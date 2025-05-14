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
            PersistentAppSettings.saveDownloadLocation(directory.path);
            log("Download location set to: ${directory.path}");
          },
        ),
        const SizedBox(width: 12),
        Text(ref.watch(downloadLocationProvider)),
      ],
    );
  }
}

class ConfigurationPage extends ConsumerWidget {
  const ConfigurationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DownloadLocationSelector(),
          DownloadLinkSelector(),
        ],
      ),
    );
  }
}

class DownloadLinkSelector extends ConsumerStatefulWidget {
  const DownloadLinkSelector({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DownloadLinkSelectorState();
}

class _DownloadLinkSelectorState extends ConsumerState<DownloadLinkSelector> {
  @override
  Widget build(BuildContext context) {
    var sourceUrlController = TextEditingController(text: ref.read(downloadSourceProvider));

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextFormField(
              onEditingComplete: () {
                log("URL: ${sourceUrlController.text}");
                PersistentAppSettings.saveDownloadLink(sourceUrlController.text);
              },
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

              if (sourceUrlController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      showCloseIcon: true,
                      content: Text("Enter a link first.")
                    )
                  );
              }
              else {
                ref.read(downloadListProvider.notifier)
                  .setDownloadSource(sourceUrlController.text);
                ref.read(downloadSourceProvider.notifier).state = sourceUrlController.text;
                PersistentAppSettings.saveDownloadLink(sourceUrlController.text);

                DefaultTabController.of(context).animateTo(1);
              }
            }
          ),
        ],
      ),
    );
  }
}

class DownloadSelectionView extends ConsumerWidget {
  const DownloadSelectionView({super.key});

  String _getFormattedDuration(Duration duration) {
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds.remainder(60);
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var downloadList = ref.watch(downloadListProvider);

    if (downloadList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Text(
            "Loading videos. If loading is taking an unusual amount of time, make sure you have set the download url to a valid YouTube video or playlist link.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              TextButton(
                child: const Row(
                  children: [
                    Icon(Icons.check_box, color: Color(0xFF44CFCB)),
                    SizedBox(width: 8),
                    Text(
                      "Select All",
                      style: TextStyle(
                        color: Color(0xFF44CFCB),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  ref.read(downloadListProvider.notifier).setAllDownloadItemSelections(true);
                  log("All items deselected.");
                }
              ),
              TextButton(
                child: const Row(
                  children: [
                    Icon(Icons.check_box_outline_blank, color: Color(0xFF44CFCB)),
                    SizedBox(width: 8),
                    Text(
                      "Deselect All",
                      style: TextStyle(
                        color: Color(0xFF44CFCB),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  ref.read(downloadListProvider.notifier).setAllDownloadItemSelections(false);
                  log("All items deselected.");
                }
              ),
              TextButton(
                child: const Row(
                  children: [
                    Icon(Icons.download, color: Color(0xFF44CFCB)),
                    SizedBox(width: 8),
                    Text(
                      "Download Selected",
                      style: TextStyle(
                        color: Color(0xFF44CFCB),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  if (ref.read(downloadListProvider).where((element) => element.isSelected).isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        showCloseIcon: true,
                        content: Text("No videos selected.")
                      )
                    );
                  }
                  else {
                    ref.read(downloadProgressProvider.notifier).setDownloadProgressTargets(ref.read(downloadListProvider), ref.read(downloadLocationProvider));
                  }
                }
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: downloadList.length,
            itemBuilder: (context, index) {
              var item = downloadList[index];
              return CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.title),
                      Text(" ${item.video?.author} | ${_getFormattedDuration(item.video?.duration ?? const Duration(seconds: 0))}"),
                    ],
                  ),
                ),
                value: item.isSelected,
                onChanged: (bool? value) {
                  ref.read(downloadListProvider.notifier).toggleDownloadItemSelection(item);
                  log("Item ${item.title} is now ${item.isSelected ? "selected" : "unselected"}");
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

