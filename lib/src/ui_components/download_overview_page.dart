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

  void setDownloadProgressTargets(List<ImmutableDownloadListItem> items, String downloadLocation, {Function(String)? onErrorReported}) {
    state = [];

    for (var item in items) {
      if (item.isSelected && item.video != null) {
        _beginDownload(item, downloadLocation, onErrorReported: onErrorReported);
      }
    }
  }

  void _beginDownload(ImmutableDownloadListItem item, String downloadPath, {Function(String)? onErrorReported}) async {
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
              onErrorReported?.call(error.toString());
              state = [
                ...state.sublist(0, index),
                DownloadProgressItem(item.url, "${item.title} - Error downloading.", item.video!, -1),
                ...state.sublist(index + 1),
              ];
              return;
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
                state = [
                  ...state.sublist(0, index),
                  DownloadProgressItem(item.url, "${item.title} - Error saving file.", item.video!, -1),
                  ...state.sublist(index + 1),
                ];
                onErrorReported?.call(error.toString());
                return;
              });
            }
            catch (error) {
              state = [
                ...state.sublist(0, index),
                DownloadProgressItem(item.url, "${item.title} - Error downloading.", item.video!, -1),
                ...state.sublist(index + 1),
              ];
              onErrorReported?.call(error.toString());
              return;
            }
          },
          onError: (error) {
            log("Error downloading video: $error");
            state = [
              ...state.sublist(0, index),
              DownloadProgressItem(item.url, "${item.title} - Error downloading file.", item.video!, -1),
              ...state.sublist(index + 1),
            ];
            onErrorReported?.call(error.toString());
            return;
          }
        ));
      }, 
      onError: (e) {
        log("Error retrieving video manifest: $e");
        state = [
          ...state.sublist(0, index),
          DownloadProgressItem(item.url, "${item.title} - Error retrieving video manifest.", item.video!, -1),
          ...state.sublist(index + 1),
        ];
        var progressItem = DownloadProgressItem(item.url, item.title, item.video!, 1);
        state = [...state.sublist(0, index), progressItem, ...state.sublist(index + 1)];
        onErrorReported?.call(extensionStreamHasListener.toString());
        return;
      });
    } catch (e) {
      log("Error downloading ${item.url}: $e");
      onErrorReported?.call(e.toString());
      return;
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
          title: Text(item.title, style: Theme.of(context).textTheme.titleSmall),
          trailing: SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: item.progress >= 0 ? item.progress : null,
              color: item.progress >= 0 ? const Color.fromARGB(255, 197, 216, 109) : const Color.fromARGB(255, 172, 57, 49),
              backgroundColor: const Color.fromARGB(255, 27, 153, 139),
              minHeight: 8,
              semanticsLabel: "Download progress for ${item.title}",
              semanticsValue: "${(item.progress * 100).toStringAsFixed(0)}%",
              borderRadius: BorderRadius.circular(8),
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