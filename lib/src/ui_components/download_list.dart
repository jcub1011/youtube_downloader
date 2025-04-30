import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:youtube_downloader/src/entities/download_request.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadListView extends StatefulWidget {
  const DownloadListView({super.key});

  @override
  State<DownloadListView> createState() => _DownloadListViewState();
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
    YouTube.instance.videos.get(url).then(
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

class _DownloadListViewState extends State<DownloadListView> {
  Map<String, DownloadListItem> downloadList = {/*
    "Invalid Test URL": DownloadListItem("Invalid Test URL"),
    "https://music.youtube.com/watch?v=ClyVKnfBIO8&si=Cu5ISm-jRwlx8oO3": DownloadListItem("https://music.youtube.com/watch?v=ClyVKnfBIO8&si=Cu5ISm-jRwlx8oO3"),
    "https://music.youtube.com/watch?v=mWl3_d3IsXg&si=-wVgfcxrQJhSguGJ": DownloadListItem("https://music.youtube.com/watch?v=mWl3_d3IsXg&si=-wVgfcxrQJhSguGJ"),*/
  };

  void setDownloadList(List<String> urls) {
    setState(() {
      downloadList = {};
      for (String url in urls) {
        downloadList[url] = DownloadListItem(url, setState);
      }
    });
  }

  void setDownloadListFromPlaylist(String playlistUrl) {
    setState(() {
      downloadList = {};
    });

    YouTube.instance.playlists.getVideos(playlistUrl).forEach((video) {
      setState(() {
        downloadList[video.url] = DownloadListItem.fromVideo(video);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        children: downloadList.keys.map((String key) {
          downloadList[key]!.setStateCallback = setState;
          
          return CheckboxListTile(
            title: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              child: Text(downloadList[key]!.title),
            ),
            value: downloadList[key]!.isSelected,
            onChanged: (bool? value) {
              setState(() {
                DownloadListItem item = downloadList[key]!;
                downloadList[key]!.isSelected = !item.isSelected;
                log("Item ${item.title} is now ${item.isSelected ? "selected" : "unselected"}");
              });
            },
          );
        }).toList()
      ),
    );
  }
}