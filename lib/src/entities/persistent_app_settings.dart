import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class DownloadSourceNotifier extends StateNotifier<String?> {
  DownloadSourceNotifier(super.state);

  void setDownloadSource(String? sourceUrl) {
    state = sourceUrl;
  }
}

final StateProvider<String> downloadLocationProvider = StateProvider<String>((ref) {
  PersistentAppSettings.readDownloadLocation().then((location) {
    ref.read(downloadLocationProvider.notifier).state = location;
  });
  return PersistentAppSettings.defaultDownloadLocation;
});

final StateProvider<String> downloadSourceProvider = StateProvider<String>((ref) {
  PersistentAppSettings.readDownloadLink().then((link) {
    ref.read(downloadSourceProvider.notifier).state = link;
  });
  return PersistentAppSettings.defaultDownloadLink;
});

class PersistentAppSettings {
  static final String _defaultDownloadLocation = Directory.current.path;
  static String get defaultDownloadLocation => _defaultDownloadLocation;
  static final String _settingsFilePath = "${Directory.current.path}/downloader_settings.txt";

  static const String defaultDownloadLink = "";
  static const String downloadLocationKey = "download_location";
  static const String downloadLinkKey = "download_link";

  /// Reads the download location from the settings file. Defaults to current directory.
  static Future<String> readDownloadLocation() {
    return readSetting(downloadLocationKey, defaultDownloadLocation);
  }

  /// Reads the download link from the settings file. Defaults to empty string.
  static Future<String> readDownloadLink() {
    return readSetting(downloadLinkKey, defaultDownloadLink);
  }

  static Future<String> readSetting(String key, String defaultValue) async {
    try {
      // Create settings if it doesn't exist.
      if (await File(_settingsFilePath).exists()) {
        log("Settings file exists.");
      }
      else {
        log("Settings file does not exist. Creating new file.");
        await File(_settingsFilePath).create();
      }
      
      return File(_settingsFilePath).openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .firstWhere((line) => line.startsWith("$key="), orElse: () => "$key=$defaultValue")
      .then((line) {
        int splitPoint = line.indexOf("=");
        String value = line.substring(splitPoint + 1);
        log("Read Setting $key: $value");
        return value;
      });
    }
    catch (e) {
      log("Error reading setting $key: $e");
      return defaultValue;
    }
  }

  /// Saves the download location to the settings file.
  static saveDownloadLocation(String location) {
    saveSetting(downloadLocationKey, location);
  }

  /// Saves the download link to the settings file.
  static saveDownloadLink(String link) {
    saveSetting(downloadLinkKey, link);
  }

  static saveSetting(String key, String value) async {
    // Create settings if it doesn't exist.
    if (await File(_settingsFilePath).exists()) {
      log("Settings file exists.");
    }
    else {
      log("Settings file does not exist. Creating new file.");
      await File(_settingsFilePath).create();
    }
    
    // Load settings data.
    var settings = File(_settingsFilePath).openRead()
    .transform(utf8.decoder)
    .transform(const LineSplitter());

    List<String> lines = [];
    try {
      await for (var line in settings) {
        lines.add(line);
      }
    }
    catch (e) {
      log("Error reading settings file: $e");
      return;
    }

    // Update setting.
    int index = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith("$key=")) {
        index = i;
        break;
      }
    }
    if (index == -1) {
      lines.add("$key=$value");
    }
    else {
      lines[index] = "$key=$value";
    }

    // Save new settings data.
    try {
      await File(_settingsFilePath).writeAsString(lines.join("\n"));
      log("Settings saved: $key=$value");
    }
    catch (e) {
      log("Error saving settings: $e");
    }
  }
}