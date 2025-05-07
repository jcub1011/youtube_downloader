import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/main.dart';
import 'package:youtube_downloader/src/entities/download_request.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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
      YTExplodeWrapper wrapper = YTExplodeWrapper(YoutubeExplode());
      wrapper.instance.videos.get(url).then(
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