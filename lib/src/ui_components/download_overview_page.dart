import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/main.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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