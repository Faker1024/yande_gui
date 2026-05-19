import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SettingsService {
  SettingsService._();

  static late final File _file;

  static const _fileName = 'settings.json';

  static final Map<String, dynamic> _map = {};

  static int? get language => _map['language'] as int?;

  static set language(int? value) {
    _map['language'] = value;
    _save();
  }

  static int? get themeMode => _map['themeMode'] as int?;

  static set themeMode(int? value) {
    _map['themeMode'] = value;
    _save();
  }

  static String get siteKey => _map['siteKey'] as String? ?? 'yande';

  static set siteKey(String value) {
    _map['siteKey'] = value;
    _save();
    _siteStreamController.add(null);
  }

  static final _siteStreamController = StreamController<void>.broadcast();

  static final siteStream = _siteStreamController.stream;

  static bool get prefetchDns => _map['prefetchDns'] as bool? ?? true;

  static set prefetchDns(bool value) {
    _map['prefetchDns'] = value;
    _save();
  }

  static int? get waterfallColumns => _map['waterfallColumns'] as int?;

  static set waterfallColumns(int? value) {
    _map['waterfallColumns'] = value;
    _save();
  }

  static String? get downloadPath => _map['downloadPath'] as String?;

  static set downloadPath(String? value) {
    _map['downloadPath'] = value;
    _save();
  }

  static String? get downloadPathBookmark =>
      _map['downloadPathBookmark'] as String?;

  static set downloadPathBookmark(String? value) {
    if (value == null) {
      _map.remove('downloadPathBookmark');
    } else {
      _map['downloadPathBookmark'] = value;
    }
    _save();
  }

  static int get maxConcurrentDownloads =>
      _map['maxConcurrentDownloads'] as int? ?? 2;

  static set maxConcurrentDownloads(int value) {
    _map['maxConcurrentDownloads'] = value;
    _save();
    _maxConcurrentDownloadsStreamController.add(null);
  }

  static final _maxConcurrentDownloadsStreamController =
      StreamController<void>.broadcast();

  static final maxConcurrentDownloadsStream =
      _maxConcurrentDownloadsStreamController.stream;

  static int get maxSegmentsPerTask => _map['maxSegmentsPerTask'] as int? ?? 3;

  static set maxSegmentsPerTask(int value) {
    _map['maxSegmentsPerTask'] = value;
    _save();
  }

  static const int _maxSearchHistoryCount = 30;
  static const int _maxDownloadHistoryCount = 100;

  static List<String> get searchHistory {
    final historyBySite = _map['searchHistoryBySite'];
    final value =
        historyBySite is Map ? historyBySite[siteKey] : _map['searchHistory'];
    if (value is! List) return [];
    return value.whereType<String>().toList(growable: false);
  }

  static void addSearchHistory(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return;

    final history = [
      normalized,
      ...searchHistory.where((item) => item != normalized),
    ];
    _setSearchHistory(
      history.take(_maxSearchHistoryCount).toList(growable: false),
    );
    _save();
  }

  static void removeSearchHistory(String value) {
    _setSearchHistory(
      searchHistory.where((item) => item != value).toList(growable: false),
    );
    _save();
  }

  static void clearSearchHistory() {
    _setSearchHistory(<String>[]);
    _save();
  }

  static void _setSearchHistory(List<String> history) {
    final historyBySite = Map<String, dynamic>.from(
      _map['searchHistoryBySite'] as Map? ?? const {},
    );
    historyBySite[siteKey] = history;
    _map['searchHistoryBySite'] = historyBySite;
  }

  static List<Map<String, dynamic>> get downloadHistory {
    final value = _map['downloadHistory'];
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static void upsertDownloadHistory(Map<String, dynamic> item) {
    final key = item['key'];
    final history = [
      item,
      ...downloadHistory.where((entry) => entry['key'] != key),
    ];
    _map['downloadHistory'] = history
        .take(_maxDownloadHistoryCount)
        .toList(growable: false);
    _save();
    _downloadHistoryStreamController.add(null);
  }

  static void removeDownloadHistory(String key) {
    _map['downloadHistory'] = downloadHistory
        .where((item) => item['key'] != key)
        .toList(growable: false);
    _save();
    _downloadHistoryStreamController.add(null);
  }

  static void clearDownloadHistory() {
    _map['downloadHistory'] = <Map<String, dynamic>>[];
    _save();
    _downloadHistoryStreamController.add(null);
  }

  static void replaceDownloadHistory(List<Map<String, dynamic>> items) {
    _map['downloadHistory'] = items;
    _save();
    _downloadHistoryStreamController.add(null);
  }

  static final _downloadHistoryStreamController =
      StreamController<void>.broadcast();

  static final downloadHistoryStream = _downloadHistoryStreamController.stream;

  static void _save() {
    _file.writeAsStringSync(json.encode(_map));
  }

  static Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux) {
      _file = File(path.join(Directory.current.path, _fileName));
    } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      final directory = await getApplicationDocumentsDirectory();
      _file = File(path.join(directory.path, _fileName));
    } else {
      throw UnsupportedError('Unsupported platform');
    }
    if (await _file.exists()) {
      try {
        _map.addAll(json.decode(_file.readAsStringSync()));
      } catch (_) {}
    }
  }
}
