import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter/services.dart';

import '../entities/download_request.dart';
import '../entities/video_retriever.dart';
import 'download_list.dart';

/// Stores the current download progress for each video.
/// Handles the download process for each video.
class DownloadProgressProvider extends StateNotifier<List<DownloadProgressItem>> {
  DownloadProgressProvider(super.state);
  
  final _ytExplode =YTExplodeWrapper(YoutubeExplode());

  void setDownloadProgressTargets(List<ImmutableDownloadListItem> items, String downloadLocation, {Function(String)? onErrorReported}) {
    state = [];

    for (var item in items) {
      if (item.isSelected && item.video != null) {
        _beginDownload(item, downloadLocation, onErrorReported: onErrorReported);
      }
    }
  }

  void _beginDownload(ImmutableDownloadListItem item, String downloadPath, {Function(String)? onErrorReported}) async {
    if (item.video == null) {
      log("Unable to download video: ${item.title} - Video is null.");
      state = [
        ...state,
        DownloadProgressItem(item.url, "${item.title} - Error retrieving video link.", item.video, -1),
      ];
      return;
    }

    var progressItem = DownloadProgressItem(item.url, item.title, item.video, 0.0);
    state = [...state, progressItem];
    int index = state.length - 1;
    log("Download started for: ${item.title}");

    try {
      // Add to queue of download requests rather than handle here. 
      //The wrapper gets discarded automatically before manifest process is finished.
      _ytExplode.instance.videos.streamsClient.getManifest(item.video!.id).then((manifest) {
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
                  DownloadProgressItem(item.url, item.title, item.video, progress, downloadURI: opusAudio.url.toString()),
                  ...state.sublist(index + 1),
                ];
              }
            }
            catch (error) {
              onErrorReported?.call(error.toString());
              state = [
                ...state.sublist(0, index),
                DownloadProgressItem(item.url, "${item.title} - Error downloading, click to copy download link.", item.video, -1, downloadURI: opusAudio.url.toString()),
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
                  DownloadProgressItem(item.url, "${item.title} - Error saving file, click to copy download link.", item.video, -1, downloadURI: opusAudio.url.toString()),
                  ...state.sublist(index + 1),
                ];
                onErrorReported?.call(error.toString());
                return;
              });
            }
            catch (error) {
              state = [
                ...state.sublist(0, index),
                DownloadProgressItem(item.url, "${item.title} - Error downloading, click to copy download link.", item.video, -1, downloadURI: opusAudio.url.toString()),
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
              DownloadProgressItem(item.url, "${item.title} - Error downloading, click to copy download link.", item.video, -1, downloadURI: opusAudio.url.toString()),
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
          DownloadProgressItem(item.url, "${item.title} - Error retrieving video manifest. Unable to get download link.", item.video, -1),
          ...state.sublist(index + 1),
        ];
        onErrorReported?.call(extensionStreamHasListener.toString());
        return;
      });
    } catch (e) {
      log("Error downloading ${item.url}: $e");
      state = [
        ...state.sublist(0, index),
        DownloadProgressItem(item.url, "${item.title} - Error retrieving video. Unable to get download link.", item.video, -1),
        ...state.sublist(index + 1),
      ];
      onErrorReported?.call(e.toString());
      return;
    }
  }
}

final downloadProgressProvider = StateNotifierProvider<DownloadProgressProvider, List<DownloadProgressItem>>((ref) {
  return DownloadProgressProvider([]);
});

/// Displays the download progress for each video.
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
          onTap: () async {
            ScaffoldMessenger.of(context).clearSnackBars();
            if (item.downloadURI == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: SelectableText("No download link available for video ${item.url}."),
                  showCloseIcon: true,

                )
              );
            }
            else {
              const int maxURIlength = 40;
              String truncatedURI = item.downloadURI!.length > maxURIlength ? "${item.downloadURI!.characters.take(maxURIlength - 3)}..." : item.downloadURI!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: SelectableText("Copied $truncatedURI to the clipboard."),
                  showCloseIcon: true,

                )
              );
              await Clipboard.setData(ClipboardData(text: item.downloadURI!));
            }
          },
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
  final Video? video;
  final double progress;
  final String? downloadURI;

  const DownloadProgressItem(this.url, this.title, this.video, this.progress, {this.downloadURI});
}