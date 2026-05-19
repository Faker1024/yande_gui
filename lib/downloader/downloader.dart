import 'dart:io';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yande_gui/services/booru_site_service.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';

import 'download_task.dart';
import 'downloader_platform.dart';
import 'platform/downloader_android.dart' as android;
import 'platform/downloader_desktop.dart' as desktop;
import 'platform/downloader_ios.dart' as ios;

class Downloader {
  static final Downloader instance = Downloader._internal();

  Downloader._internal();

  static bool _initialized = false;

  late final DownloaderPlatform<Post> _platform = _selectPlatformDownloader();

  DownloaderPlatform<Post> _selectPlatformDownloader() {
    if (Platform.isAndroid) {
      return android.DownloaderAndroid();
    } else if (Platform.isIOS) {
      return ios.DownloaderIOS();
    } else {
      return desktop.DownloaderDesktop();
    }
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await _platform.init();
  }

  int count = 0;

  Future<void> addTask({
    required String taskId,
    required Post inner,
    required String url,
    required String fileName,
  }) {
    return _platform.addTask(
      taskId: taskId,
      inner: inner,
      url: url,
      fileName: fileName,
    );
  }

  Future<void> startTask(String taskId) {
    return _platform.startTask(taskId);
  }

  Future<void> retryAll() {
    return _platform.retryAll();
  }

  Future<void> add(Post post) async {
    final url =
        post.fileUrl ?? post.jpegUrl ?? post.sampleUrl ?? post.previewUrl;
    if (!_isHttpUrl(url)) {
      EasyLoading.showError('No downloadable image URL.');
      return;
    }

    final site = BooruSite.fromUrl(url);
    final fileNamePrefix = switch (site) {
      BooruSite.konachan => 'konachan_',
      BooruSite.danbooru => 'danbooru_',
      _ => '',
    };
    final fileExt = _fileExtFromUrl(url) ?? post.fileExt;

    return _platform.addTask(
      taskId: (count++).toString(),
      inner: post,
      url: url,
      fileName: '$fileNamePrefix${post.id}.$fileExt',
    );
  }

  Stream<List<DownloadTask<Post>>> get taskListStream {
    return _platform.taskListStream;
  }

  List<DownloadTask<Post>> get taskList => _platform.taskList;

  void cancelTask(String taskId) {
    _platform.cancelTask(taskId);
  }
}

String? _fileExtFromUrl(String url) {
  final path = Uri.tryParse(url)?.path;
  if (path == null || path.isEmpty) return null;

  final fileName = path.split('/').last;
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return null;

  return fileName.substring(dot + 1).toLowerCase();
}

bool _isHttpUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}
