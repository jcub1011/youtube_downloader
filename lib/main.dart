import 'package:flutter/material.dart';

import 'src/ui_components/my_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  runApp(const ProviderScope(child: DownloaderApp()));
}

