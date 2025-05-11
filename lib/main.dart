import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:youtube_downloader/src/entities/video_retriever.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'src/entities/download_request.dart';
import 'src/ui_components/download_list.dart';
import 'src/ui_components/download_overview_page.dart';
import 'src/ui_components/my_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
//import 'src/settings/settings_controller.dart';
//import 'src/settings/settings_service.dart';

void main() async {
  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  //final settingsController = SettingsController(SettingsService());

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  //await settingsController.loadSettings();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(const ProviderScope(child: DownloaderApp()));
}

class DownloadSourceNotifier extends StateNotifier<String?> {
  DownloadSourceNotifier(super.state);

  void setDownloadSource(String? sourceUrl) {
    state = sourceUrl;
  }
}

class DownloadListItemsProvider extends StateNotifier<List<ImmutableDownloadListItem>> {
  DownloadListItemsProvider(super.state);

  void setDownloadSource(String sourceUrl) {
    if (sourceUrl.contains("watch?v=")) {
      _getVideo(sourceUrl);
    }
    else {
      _getVideos(sourceUrl);
    }
  }
  
  void _getVideo(String videoLink) {
    clearDownloadItems();

    try {
      YTExplodeWrapper wrapper = YTExplodeWrapper(YoutubeExplode());
      wrapper.instance.videos.get(videoLink).then(
        (Video video) {
          _addDownloadItem(videoLink, video.title, true, video);
          log("Video title: ${video.title}");
        },
        onError: (error) {
          _addDownloadItem(videoLink, "Error retrieving video title.", true, null);
          log("Error retrieving video title: $error");
        },
      );
    }
    catch (e) {
      log("Error retrieving video title: $e");
      _addDownloadItem(videoLink, "Error retrieving video title.", true, null);
    }
  }

  void _getVideos(String playlistLink) {
    clearDownloadItems();

    try {
      YTExplodeWrapper wrapper = YTExplodeWrapper(YoutubeExplode());
      wrapper.instance.playlists.get(playlistLink).then(
        (Playlist playlist) {
          wrapper.instance.playlists.getVideos(playlistLink).forEach((video) {
            _addDownloadItem(video.url, video.title, true, video);
          });
        },
        onError: (error) {
          _addDownloadItem(playlistLink, "Error retrieving video(s).", true, null);
          log("Error retrieving video(s): $error");
        },
      );
    }
    catch (e) {
      log("Error retrieving video(s).: $e");
      _addDownloadItem(playlistLink, "Error retrieving video(s).", true, null);
    }
  }

  void _addDownloadItem(String url, String title, bool isSelected, Video? video) {
    state = [...state, ImmutableDownloadListItem(url, title, video: video, isSelected: isSelected)];
  }

  void toggleDownloadItemSelection(ImmutableDownloadListItem item) {
    final index = state.indexOf(item);
    if (index != -1) {
      final updatedItem = ImmutableDownloadListItem(
        item.url,
        item.title,
        video: item.video,
        isSelected: !item.isSelected,
      );
      
      state = [
        ...state.sublist(0, index),
        updatedItem,
        ...state.sublist(index + 1),
      ];
    }
  }

  void removeDownloadItem(int index) {
    var toRemove = state[index];
    removeDownloadItemByItem(toRemove);
  }

  void removeDownloadItemByItem(ImmutableDownloadListItem item) {
    state = [
      ...state.where((element) => element != item),
    ];
  }

  void clearDownloadItems() {
    state = [];
  }
}

class DownloadProgressProvider extends StateNotifier<List<DownloadProgressItem>> {
  DownloadProgressProvider(super.state);

  void setDownloadProgressTargets(List<ImmutableDownloadListItem> items) {
    state = [];

    for (var item in items) {
      if (item.isSelected && item.video != null) {
        _beginDownload(item);
      }
    }
  }

  void _beginDownload(ImmutableDownloadListItem item) async {
    var progressItem = DownloadProgressItem(item.url, item.title, item.video!, 0.0);
    state = [...state, progressItem];
    int index = state.length - 1;
    log("Download started for: ${item.title}");

    try {
      // Add to queue of download requests rather than handle here. 
      //The wrapper gets discarded automatically before manifest process is finished.
      YTExplodeWrapper wrapper = YTExplodeWrapper(YoutubeExplode());
      wrapper.instance.videos.streamsClient.getManifest(item.video!.id).then((manifest) {
        var audioInfo = manifest.audioOnly.withHighestBitrate();
        log("Highest Audio Bitrate: ${audioInfo.bitrate}");
        log("Audio URL: ${audioInfo.url}");

        int total = 0;
        int received = 0;
        int previousPercent = 0;
        List<int> bytes = [];

        videoDownloader.addToQueue(VideoDownloadRequestArgs
        (
          url: audioInfo.url,
          onStart: (response) {
            total = response.contentLength ?? 0;
          },
          onData: (data) {
            received += data.length;

            double progress = received / total;
            int currentPercent = (progress * 100).toInt();
            currentPercent = currentPercent - currentPercent % 5; // Round down to nearest 5%.

            if (currentPercent != previousPercent) {
              log("Progress: $currentPercent%");
              previousPercent = currentPercent;
              state = [
                ...state.sublist(0, index),
                DownloadProgressItem(item.url, item.title, item.video!, progress),
                ...state.sublist(index + 1),
              ];
            }
          },
          onDone: (allData) {
            bytes = allData;
            log("Download completed for: ${item.title}");
          },
          onError: (error) {
            log("Error downloading video: $error");
            state = [
              ...state.sublist(0, index),
              DownloadProgressItem(item.url, item.title, item.video!, 0.0),
              ...state.sublist(index + 1),
            ];
          }
        ));
      }, 
      onError: (e) {
        log("Error retrieving video manifest: $e");
        return null;
      });
    } catch (e) {
      log("Error downloading ${item.url}: $e");
      return null;
    }
  }

  String _getPath(Video video, StreamInfo streamInfo) {
    String folder = Directory.current.path;
    log("Current folder: $folder");
    String fileName = video.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_') + streamInfo.container.name;
    String filePath = "$folder/$fileName";
    return filePath;
  }
}

final downloadListProvider = StateNotifierProvider<DownloadListItemsProvider, List<ImmutableDownloadListItem>>((ref) {
  return DownloadListItemsProvider([]);
});

final downloadProgressProvider = StateNotifierProvider<DownloadProgressProvider, List<DownloadProgressItem>>((ref) {
  return DownloadProgressProvider([]);
});

final videoDownloader = VideoDownloader(2);