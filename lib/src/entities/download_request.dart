import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadRequestArgs {
  final bool isAudioOnly;

  DownloadRequestArgs(this.isAudioOnly);
}

// Singleton class for YoutubeExplode.
class YouTube {
  static final _instance = YoutubeExplode();
  static YoutubeExplode get instance => _instance;
}

/// Holds relevant information for a download request.
class DownloadRequest {
  final Video video;
  final DownloadRequestArgs downloadArgs;

  DownloadRequest(this.video, this.downloadArgs);
}