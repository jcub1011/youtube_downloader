import 'dart:convert';
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
import 'package:mime/mime.dart';
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
    PersistentAppSettings.saveDownloadLink(sourceUrl);
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

  void setAllDownloadItemSelections(bool isSelected) {
    if (state.isEmpty) return;

    state = state.map((item) {
      return ImmutableDownloadListItem(
        item.url,
        item.title,
        video: item.video,
        isSelected: isSelected,
      );
    }).toList();
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

  void setDownloadProgressTargets(List<ImmutableDownloadListItem> items, String downloadLocation) {
    state = [];

    for (var item in items) {
      if (item.isSelected && item.video != null) {
        _beginDownload(item, downloadLocation);
      }
    }
  }

  void _beginDownload(ImmutableDownloadListItem item, String downloadPath) async {
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
        for (int i = 0; i < manifest.audioOnly.length; i++) {
          log("Audio ${i + 1}: ${manifest.audioOnly[i].bitrate} ${manifest.audioOnly[i].codec.mimeType} ${manifest.audioOnly[i].audioCodec}");
        }

        String audioExtension = 'opus';
        var opusAudio = manifest.audioOnly.sortByBitrate().firstWhere((audio) {
          return audio.audioCodec.toLowerCase() == "opus";
        }, orElse: () {
          log("No Opus audio found, using highest bitrate.");
          audioExtension = extensionFromMime(audioInfo.codec.mimeType) ?? 'mp3';
          return audioInfo;
        });
        log("Selected Audio: ${opusAudio.bitrate} ${opusAudio.codec.mimeType} ${opusAudio.audioCodec}");
        log("Audio URL: ${opusAudio.url}");

        int total = 0;
        int received = 0;
        int previousPercent = 0;

        videoDownloader.addToQueue(VideoDownloadRequestArgs
        (
          url: opusAudio.url,
          onStart: (response) {
            total = response.contentLength ?? 0;
          },
          onData: (data) {
            try {
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
            }
            catch (error) {
              VideoDownloader.errorEvent.broadcast(error.toString());
            }
          },
          onDone: (allData) {
            try {
              log("Network download completed for: ${item.title}");

              var file = File('$downloadPath/${item.video!.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.$audioExtension');
              file.writeAsBytes(allData).then((file) {
                log("File saved to: ${file.path}");
              }).catchError((error) {
                log("Error saving file: $error");
              });
            }
            catch (error) {
              VideoDownloader.errorEvent.broadcast(error.toString());
            }
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
        var progressItem = DownloadProgressItem(item.url, item.title, item.video!, 1);
        state = [...state.sublist(0, index), progressItem, ...state.sublist(index + 1)];
        return null;
      });
    } catch (e) {
      log("Error downloading ${item.url}: $e");
      return null;
    }
  }
}

final downloadListProvider = StateNotifierProvider<DownloadListItemsProvider, List<ImmutableDownloadListItem>>((ref) {
  return DownloadListItemsProvider([]);
});

final downloadProgressProvider = StateNotifierProvider<DownloadProgressProvider, List<DownloadProgressItem>>((ref) {
  return DownloadProgressProvider([]);
});

final videoDownloader = VideoDownloader(5);

final StateProvider<String> downloadLocationProvider = StateProvider<String>((ref) {
  PersistentAppSettings.readDownloadLocation().then((location) {
    ref.read(downloadLocationProvider.notifier).state = location;
  });
  return PersistentAppSettings.defaultDownloadLocation;
});

final StateProvider<String> downloadSourceProvider = StateProvider<String>((ref) {
  PersistentAppSettings.readDownloadLink().then((link) {
    ref.read(downloadSourceProvider.notifier).state = link;
  });
  return PersistentAppSettings.defaultDownloadLink;
});

final errorListProvider = StateProvider<List<String>>((ref) {
  return List<String>.empty();
});

class PersistentAppSettings {
  static final String _defaultDownloadLocation = Directory.current.path;
  static String get defaultDownloadLocation => _defaultDownloadLocation;
  static final String _settingsFilePath = "${Directory.current.path}/downloader_settings.txt";

  static const String defaultDownloadLink = "";
  static const String downloadLocationKey = "download_location";
  static const String downloadLinkKey = "download_link";

  /// Reads the download location from the settings file. Defaults to current directory.
  static Future<String> readDownloadLocation() {
    return readSetting(downloadLocationKey, defaultDownloadLocation);
  }

  /// Reads the download link from the settings file. Defaults to empty string.
  static Future<String> readDownloadLink() {
    return readSetting(downloadLinkKey, defaultDownloadLink);
  }

  static Future<String> readSetting(String key, String defaultValue) async {
    try {
      // Create settings if it doesn't exist.
      if (await File(_settingsFilePath).exists()) {
        log("Settings file exists.");
      }
      else {
        log("Settings file does not exist. Creating new file.");
        await File(_settingsFilePath).create();
      }
      
      return File(_settingsFilePath).openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .firstWhere((line) => line.startsWith("$key="), orElse: () => "$key=$defaultValue")
      .then((line) {
        int splitPoint = line.indexOf("=");
        String value = line.substring(splitPoint + 1);
        log("Read Setting $key: $value");
        return value;
      });
    }
    catch (e) {
      log("Error reading setting $key: $e");
      return defaultValue;
    }
  }

  /// Saves the download location to the settings file.
  static saveDownloadLocation(String location) {
    saveSetting(downloadLocationKey, location);
  }

  /// Saves the download link to the settings file.
  static saveDownloadLink(String link) {
    saveSetting(downloadLinkKey, link);
  }

  static saveSetting(String key, String value) async {
    // Create settings if it doesn't exist.
    if (await File(_settingsFilePath).exists()) {
      log("Settings file exists.");
    }
    else {
      log("Settings file does not exist. Creating new file.");
      await File(_settingsFilePath).create();
    }
    
    // Load settings data.
    var settings = File(_settingsFilePath).openRead()
    .transform(utf8.decoder)
    .transform(const LineSplitter());

    List<String> lines = [];
    try {
      await for (var line in settings) {
        lines.add(line);
      }
    }
    catch (e) {
      log("Error reading settings file: $e");
      return;
    }

    // Update setting.
    int index = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith("$key=")) {
        index = i;
        break;
      }
    }
    if (index == -1) {
      lines.add("$key=$value");
    }
    else {
      lines[index] = "$key=$value";
    }

    // Save new settings data.
    try {
      await File(_settingsFilePath).writeAsString(lines.join("\n"));
      log("Settings saved: $key=$value");
    }
    catch (e) {
      log("Error saving settings: $e");
    }
  }
}