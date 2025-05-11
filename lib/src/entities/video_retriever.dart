import 'dart:collection';
import 'dart:io';

import 'package:http/http.dart';
import 'package:http/io_client.dart';

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
  final Queue<DownloadRequestArgs> _queue; 
  final Queue<Client> _clientPool = Queue<Client>();
  final Queue<Client> _activeClients = Queue<Client>();

  VideoDownloader(this._maxConcurrentDownloads) : 
  _queue = Queue<DownloadRequestArgs>() 
  {
    while (_clientPool.length + _activeClients.length < _maxConcurrentDownloads) {
      _clientPool.add(Client());
    }
  }

  set maxConcurrentDownloads(int max) {
    _maxConcurrentDownloads = max;
    
    while (_clientPool.length + _activeClients.length < _maxConcurrentDownloads) {
      _clientPool.add(Client());
    }

    while (_clientPool.length + _activeClients.length > _maxConcurrentDownloads) {
      if (_clientPool.isNotEmpty) {
        _clientPool.removeLast().close();
      } else {
        break;
      }
    }
  }

  void addToQueue(DownloadRequestArgs args) {
    _queue.add(args);

    // Start download process if not already running.
  }

  void dispose() {
    while (_clientPool.isNotEmpty) {
      _clientPool.removeLast().close();
    }

    while (_activeClients.isNotEmpty) {
      _activeClients.removeLast().close();
    }
  }
}