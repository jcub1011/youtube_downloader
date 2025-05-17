import 'dart:collection';
import 'dart:developer';
import 'package:http/http.dart' as http;

final videoDownloader = VideoDownloader(5);

/// Contains all the relevant information for a video download request.
class VideoDownloadRequestArgs {
  final Uri url;
  /// Called when request is started.
  final Function(http.StreamedResponse)? onStart;
  /// List of bytes received for the current chunk.
  final Function(List<int>)? onData;
  /// List of all bytes received.
  final Function(List<int>)? onDone;
  /// Called when an error occurs.
  final Function(dynamic)? onError;

  VideoDownloadRequestArgs({
    required this.url,
    this.onStart,
    this.onData,
    this.onDone,
    this.onError,
  });
}

/// Handles the downloading of videos using the http library.
class VideoDownloader {
  int _maxConcurrentDownloads; 
  /// Queue of videos to download.
  final Queue<VideoDownloadRequestArgs> _queue; 
  final Queue<http.Client> _clientPool = Queue<http.Client>();
  final Queue<http.Client> _activeClients = Queue<http.Client>();

  VideoDownloader(this._maxConcurrentDownloads) : 
  _queue = Queue<VideoDownloadRequestArgs>() 
  {
    while (_clientPool.length + _activeClients.length < _maxConcurrentDownloads) {
      _clientPool.add(http.Client());
    }
  }

  set maxConcurrentDownloads(int max) {
    _maxConcurrentDownloads = max;
    
    while (_clientPool.length + _activeClients.length < _maxConcurrentDownloads) {
      _clientPool.add(http.Client());
    }

    while (_clientPool.length + _activeClients.length > _maxConcurrentDownloads) {
      if (_clientPool.isNotEmpty) {
        _clientPool.removeLast().close();
      } else {
        break;
      }
    }
  }

  void addToQueue(VideoDownloadRequestArgs args) {
    _queue.add(args);

    // Start download process.
    startDownloads();
  }

  /// Begins the downloads.
  void startDownloads() {
    try {
      while (_clientPool.isNotEmpty && _queue.isNotEmpty) {
        var request = _queue.removeFirst();
        var client = _clientPool.removeFirst();
        _activeClients.add(client);

        List<int> bytes = [];

        try {
          client.send(http.Request('GET', request.url)).then((response) {
            if (request.onStart != null) {
              request.onStart!(response);
            }

            response.stream.listen((value) {
              bytes.addAll(value);

              if (request.onData != null) {
                request.onData!(value);
              }
            },
            onDone:() {
              _activeClients.remove(client);
              _clientPool.add(client);

              startDownloads();

              if (request.onDone != null) {
                request.onDone!(bytes);
              }
            },
            cancelOnError: true,
            onError: (error) {
              log("Error downloading video: $error");

              // Replace client.
              _activeClients.remove(client);
              client.close();
              _clientPool.add(http.Client());

              // Begin new downloads.
              startDownloads();

              if (request.onError != null) {
                request.onError!(error);
              }
            });
          },
          onError: (error) {
            log("Error downloading video: $error");

            // Replace client.
            _activeClients.remove(client);
            client.close();
            _clientPool.add(http.Client());

            // Begin new downloads.
            startDownloads();

            if (request.onError != null) {
              request.onError!(error);
            }
          });
        }
        catch (error) {
          log("Error downloading video: $error");

          // Replace client.
          _activeClients.remove(client);
          client.close();
          _clientPool.add(http.Client());

          // Begin new downloads.
          startDownloads();

          if (request.onError != null) {
            request.onError!(error);
          }
        }
      }
    }
    catch (error) {
      log("Error starting downloads: $error");
      log("Unable to recover from error. Cancelling all downloads.");
      log("Please restart the application.");
    }
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