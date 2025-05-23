import 'dart:developer';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadRequestArgs {
  final bool isAudioOnly;

  DownloadRequestArgs(this.isAudioOnly);
}

class YTExplodeWrapper {
  static final Finalizer<YoutubeExplode> _finalizer = Finalizer<YoutubeExplode>((instance) {
    //instance.close();
    log("YoutubeExplode instance closed.");
  });

  final YoutubeExplode _ytExplode;
  YoutubeExplode get instance => _ytExplode;

  YTExplodeWrapper(this._ytExplode) {
    _finalizer.attach(this, _ytExplode, detach: this);
    log("YoutubeExplode instance initialized.");
  }

  void close() {
    _ytExplode.close();
    _finalizer.detach(this);
    log("YoutubeExplode instance closed and detached.");
  }
}