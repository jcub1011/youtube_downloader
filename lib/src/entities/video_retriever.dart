import 'dart:collection';

class DownloadRequestArgs {
  final String url;
  final Function? onStart;
  final Function? onData;
  final Function? onDone;
  final Function? onError;
  final bool? cancelOnError;

  DownloadRequestArgs({
    required this.url,
    this.onStart,
    this.onData,
    this.onDone,
    this.onError,
    this.cancelOnError,
  });
}

class VideoDownloader {
  int _maxConcurrentDownloads; 
  /// Queue of videos to download.
  Queue<DownloadRequestArgs> queue; 

  VideoDownloader(this._maxConcurrentDownloads) : queue = Queue<DownloadRequestArgs>();

  set maxConcurrentDownloads(int max) {
    _maxConcurrentDownloads = max;
  }

  void addToQueue(DownloadRequestArgs args) {
    queue.add(args);
  }
}