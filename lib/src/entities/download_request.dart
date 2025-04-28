import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadRequestArgs {
  final bool isAudioOnly;

  DownloadRequestArgs(this.isAudioOnly);
}

/// Holds relevant information for a download request.
class DownloadRequest {
  final Video video;
  final DownloadRequestArgs downloadArgs;

  DownloadRequest(this.video, this.downloadArgs);
}