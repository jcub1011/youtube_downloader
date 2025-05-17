import 'dart:developer';

import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/persistent_app_settings.dart';
import 'download_list.dart';

/// Handles getting the download location from the user.
class DownloadLocationSelector extends ConsumerWidget {
  const DownloadLocationSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        TextButton(
          style: Theme.of(context).textButtonTheme.style,
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
        Text(
          ref.watch(downloadLocationProvider),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }
}

/// Displays the configuration settings for the app.
class ConfigurationPage extends ConsumerWidget {
  const ConfigurationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This is pretty jank, but I don't know better alternatives without a major refactor.
    return const Padding(
      padding: EdgeInsets.all(12.0),
      child: Column(
        spacing: 12,
        children: [
          SizedBox(height: 0),
          DownloadLocationSelector(),
          DownloadLinkSelector(),
        ],
      ),
    );
  }
}

/// Handles getting the download link from the user.
class DownloadLinkSelector extends ConsumerStatefulWidget {
  const DownloadLinkSelector({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DownloadLinkSelectorState();
}

class _DownloadLinkSelectorState extends ConsumerState<DownloadLinkSelector> {
  @override
  Widget build(BuildContext context) {
    var sourceUrlController = TextEditingController(text: ref.read(downloadSourceProvider));

    return Column(
      spacing: 12,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextFormField(
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
              color: Color.fromARGB(255, 27, 153, 139),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          style: Theme.of(context).textButtonTheme.style,
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
          },
          child: const Text(
            "Load Download List",
          ),
        ),
      ],
    );
  }
}