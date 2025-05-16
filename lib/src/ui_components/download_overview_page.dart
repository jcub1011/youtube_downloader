import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../entities/download_request.dart';
import '../entities/video_retriever.dart';
import 'download_list.dart';

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

final downloadProgressProvider = StateNotifierProvider<DownloadProgressProvider, List<DownloadProgressItem>>((ref) {
  return DownloadProgressProvider([]);
});

class DownloadOverviewPage extends ConsumerWidget {
  const DownloadOverviewPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var downloadList = ref.watch(downloadProgressProvider);
    return ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: downloadList.length,
      itemBuilder: (context, index) {
        var item = downloadList[index];
        return ListTile(
          title: Text(item.title),
          trailing: SizedBox(
            width: 150,
            child: LinearProgressIndicator(
              value: item.progress,
              backgroundColor: Colors.grey,
              color: Colors.blue,
              minHeight: 5,
            ),
          ),
        );
      },
    );
  }
}

@immutable
class DownloadProgressItem {
  final String url;
  final String title;
  final Video video;
  final double progress;

  const DownloadProgressItem(this.url, this.title, this.video, this.progress);
}