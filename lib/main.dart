import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'src/entities/download_request.dart';
import 'src/ui_components/download_list.dart';
import 'src/ui_components/my_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      YouTube.instance.videos.get(videoLink).then(
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
      YouTube.instance.playlists.get(playlistLink).then(
        (Playlist playlist) {
          YouTube.instance.playlists.getVideos(playlistLink).forEach((video) {
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

final downloadListProvider = StateNotifierProvider<DownloadListItemsProvider, List<ImmutableDownloadListItem>>((ref) {
  return DownloadListItemsProvider([]);
});