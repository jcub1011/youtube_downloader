import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/src/entities/download_request.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../entities/persistent_app_settings.dart';
import 'download_overview_page.dart';

/// Stores the download list items.
class DownloadListItemsProvider extends StateNotifier<List<ImmutableDownloadListItem>> {
  DownloadListItemsProvider(super.state);
  final YoutubeExplode _ytExplode = YoutubeExplode();

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
      _ytExplode.videos.get(videoLink).then(
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
      _ytExplode.playlists.get(playlistLink).then(
        (Playlist playlist) {
          _ytExplode.playlists.getVideos(playlistLink).forEach((video) {
            _addDownloadItem(video.url, video.title, true, video);
          });
        },
        onError: (error) {
          log("Error retrieving video(s): $error");
          _addDownloadItem(playlistLink, "Error retrieving video(s).", true, null);
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

final downloadListProvider = StateNotifierProvider<DownloadListItemsProvider, List<ImmutableDownloadListItem>>((ref) {
  return DownloadListItemsProvider([]);
});

/// Displays the items in the download list.
class DownloadListView extends ConsumerWidget {
  const DownloadListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var downloadList = ref.watch(downloadListProvider);

    return ListView.builder(
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
            child: Text(item.title),
          ),
          value: item.isSelected,
          onChanged: (bool? value) {
            ref.read(downloadListProvider.notifier).toggleDownloadItemSelection(item);
            log("Item ${item.title} is now ${item.isSelected ? "selected" : "unselected"}");
          },
        );
      },
    );
  }
}

@immutable
class ImmutableDownloadListItem {
  final String url;
  final String title;
  final Video? video;
  final bool isSelected;

  const ImmutableDownloadListItem(this.url, this.title, {this.video, this.isSelected = true});
}

class DownloadListItem {
  final String _url;
  String _title;
  Video? _video;
  bool isSelected = true;
  void Function(void Function())? _setStateCallback;
  final _ytExplode = YTExplodeWrapper(YoutubeExplode());

  DownloadListItem(String url, [void Function(void Function())? setStateCallback])
      : _url = url,
        _title = "Retrieving video title...",
        isSelected = true {
    _setStateCallback = setStateCallback;

    try {
      getVideo(url);
    } catch (e) {
      log("Error retrieving video title: $e");
      _title = "Error retrieving video title for $url";
      if (_setStateCallback != null) {
        _setStateCallback!(() {/** Video title updated. */});
      }
    }
  }

  DownloadListItem.fromVideo(Video video)
      : _url = video.url,
        _title = video.title,
        isSelected = true;

  void getVideo(String link) {
      _ytExplode.instance.videos.get(url).then(
      (Video video) {
        _video = video;
        _title = video.title;
        log("Video title: $_title");
        if (_setStateCallback != null) {
          _setStateCallback!(() {/** Video title updated. */});
        }
      },
      onError: (error) {
        log("Error retrieving video title: $error");
        _title = "Error retrieving video title.";
        if (_setStateCallback != null) {
          _setStateCallback!(() {/** Video title updated. */});
        }
      },
    );
  }

  Video? get video => _video;
  String get url => _url;
  String get title => _title;
  set setStateCallback(void Function(void Function())? callback) {
    _setStateCallback = callback;
  }
}

/// Allows the user to select which videos to download.
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
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            spacing: 12,
            children: [
              TextButton(
                child: const Row(
                  children: [
                    Icon(Icons.check_box),
                    SizedBox(width: 8),
                    Text(
                      "Select All",
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
                    Icon(Icons.check_box_outline_blank),
                    SizedBox(width: 8),
                    Text(
                      "Deselect All",
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
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text(
                      "Download Selected",
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
                    DefaultTabController.of(context).animateTo(2);
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
                fillColor: WidgetStateProperty.all<Color>(const Color.fromARGB(0, 244, 96, 54)),
                checkboxScaleFactor: 1.25,
                controlAffinity: ListTileControlAffinity.leading,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.title, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      " ${item.video?.author} | ${_getFormattedDuration(item.video?.duration ?? const Duration(seconds: 0))}",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
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