import 'dart:async';
import 'dart:io';
import 'dart:developer';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/services/download_history_service.dart';
import 'package:yande_gui/services/macos_security_scoped_bookmark_service.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:path/path.dart' as path;

import '../download_task.dart';
import '../downloader_platform.dart';
import 'download_queue_manger.dart';

class DownloaderDesktop<T> extends DownloaderPlatform<T> {
  final _downloadQueueManager = DownloadQueueManager(
    getMaxConcurrentDownloads: () => SettingsService.maxConcurrentDownloads,
    downloadFile: _downloadWithCurlFallback,
  );

  Future<void> _moveFile(String sourcePath, String targetPath) async {
    final sourceFile = File(sourcePath);
    final targetFile = File(targetPath);

    final targetDir = targetFile.parent;
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    try {
      await sourceFile.rename(targetPath);
    } catch (e) {
      try {
        await sourceFile.copy(targetPath);
        await sourceFile.delete();
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<R> _withDownloadDirectoryAccess<R>(Future<R> Function() action) async {
    final shouldUseBookmark =
        Platform.isMacOS && SettingsService.downloadPath != null;

    if (!shouldUseBookmark) {
      return action();
    }

    final accessPath = await MacOSSecurityScopedBookmarkService.startAccessing(
      SettingsService.downloadPathBookmark,
    );

    try {
      return await action();
    } finally {
      await MacOSSecurityScopedBookmarkService.stopAccessing(accessPath);
    }
  }

  @override
  Future<void> init() async {
    // no init
  }

  @override
  Future<bool> checkPrerequisites(DownloadTask task) async {
    final downloadDir = await getDownloadsDirectory();
    final File file;
    if (SettingsService.downloadPath case String downloadPath) {
      file = File(path.join(downloadPath, task.fileName));
    } else {
      file = File(path.join(downloadDir!.path, 'YandeGUI', task.fileName));
    }
    try {
      final exists = await _withDownloadDirectoryAccess(() => file.exists());
      if (exists) {
        EasyLoading.showError(i18n.downloads.messages.imageFileExists);
        return false;
      }
    } catch (e) {
      EasyLoading.showError(e.toString());
      return false;
    }
    return true;
  }

  @override
  Future<void> handleTask(DownloadTask task) async {
    final cacheDirectory = await getApplicationCacheDirectory();

    final downloadsCachePath = path.join(cacheDirectory.path, 'yande_gui');

    final filePath = path.join(downloadsCachePath, task.fileName);

    _downloadQueueManager.startTask(
      taskId: task.taskId,
      url: task.url,
      filePath: filePath,
      maxSegmentsPerTask: SettingsService.maxSegmentsPerTask,
      onEvent: (event) async {
        switch (event) {
          case DownloadEventStart():
            task.emit(task.state.copyWith(status: DownloadStatus.busying));
            break;
          case DownloadEventProgress(:final value):
            task.emit(
              task.state.copyWith(
                status: DownloadStatus.busying,
                progress: value,
              ),
            );
            break;
          case DownloadEventSuccess():
            final downloadDir = await getDownloadsDirectory();
            final String targetPath;
            if (SettingsService.downloadPath case String downloadPath) {
              targetPath = path.join(downloadPath, task.fileName);
            } else {
              targetPath = path.join(
                downloadDir!.path,
                'YandeGUI',
                task.fileName,
              );
            }
            try {
              await _withDownloadDirectoryAccess(() {
                return _moveFile(filePath, targetPath);
              });
              DownloadHistoryService.record(
                inner: task.inner,
                fileName: task.fileName,
                url: task.url,
                status: DownloadHistoryStatus.completed,
                filePath: targetPath,
              );

              EasyLoading.showSuccess(
                i18n.downloads.messages.downloadCompletedWith(task.fileName),
              );
              task.emit(task.state.copyWith(status: DownloadStatus.completed));
            } catch (e) {
              log('save error:$e');
              DownloadHistoryService.record(
                inner: task.inner,
                fileName: task.fileName,
                url: task.url,
                status: DownloadHistoryStatus.failed,
                filePath: targetPath,
                error: e.toString(),
              );
              EasyLoading.showError(
                i18n.downloads.messages.saveFailedWith(task.fileName),
              );
              task.emit(
                task.state.copyWith(
                  status: DownloadStatus.failed,
                  error: e.toString(),
                ),
              );
            }
            break;
          case DownloadEventError(:final error):
            log('download error:$error');
            DownloadHistoryService.record(
              inner: task.inner,
              fileName: task.fileName,
              url: task.url,
              status: DownloadHistoryStatus.failed,
              error: error,
            );
            EasyLoading.showError(
              i18n.downloads.messages.downloadFailedWith(task.fileName),
            );
            task.emit(
              task.state.copyWith(status: DownloadStatus.failed, error: error),
            );
            break;
        }
      },
    );
  }

  @override
  void cancelTask(String taskId) {}
}

Future<void> _downloadWithCurlFallback({
  required String url,
  required String filePath,
  required int maxSegmentsPerTask,
  required FutureOr<void> Function(BigInt received, BigInt total)
  progressCallback,
}) async {
  try {
    await downloadClient.downloadToFile(
      url: url,
      filePath: filePath,
      maxTaskCount: maxSegmentsPerTask,
      progressCallback: progressCallback,
    );
  } catch (error) {
    if (!_canUseCurlFallback(url)) {
      rethrow;
    }

    log('download fallback to curl:$error');
    await _downloadWithCurl(
      url: url,
      filePath: filePath,
      progressCallback: progressCallback,
    );
  }
}

bool _canUseCurlFallback(String url) {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isWindows) {
    return false;
  }

  final host = Uri.tryParse(url)?.host;
  return host == 'cdn.donmai.us' || (host?.endsWith('.cdn.donmai.us') ?? false);
}

Future<void> _downloadWithCurl({
  required String url,
  required String filePath,
  required FutureOr<void> Function(BigInt received, BigInt total)
  progressCallback,
}) async {
  final target = File(filePath);
  await target.parent.create(recursive: true);

  final tempPath = '$filePath.curl';
  final tempFile = File(tempPath);
  if (await tempFile.exists()) {
    await tempFile.delete();
  }

  await progressCallback(BigInt.zero, BigInt.one);

  final executable = Platform.isMacOS ? '/usr/bin/curl' : 'curl';
  final result = await Process.run(executable, [
    '--fail',
    '--location',
    '--silent',
    '--show-error',
    '--retry',
    '2',
    '--retry-delay',
    '1',
    '--connect-timeout',
    '20',
    '--output',
    tempPath,
    url,
  ]);

  if (result.exitCode != 0) {
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    final stderr = result.stderr.toString().trim();
    throw Exception(stderr.isEmpty ? 'curl download failed' : stderr);
  }

  await _validateDownloadedFile(tempFile);

  if (await target.exists()) {
    await target.delete();
  }
  await tempFile.rename(filePath);

  final size = await target.length();
  await progressCallback(BigInt.from(size), BigInt.from(size));
}

Future<void> _validateDownloadedFile(File file) async {
  final bytes = await file
      .openRead(0, 512)
      .fold<List<int>>(<int>[], (buffer, chunk) => buffer..addAll(chunk));

  if (bytes.isEmpty) {
    await file.delete();
    throw Exception('Downloaded file is empty.');
  }

  final textPrefix =
      String.fromCharCodes(bytes.take(64)).trimLeft().toLowerCase();
  if (textPrefix.startsWith('<!doctype html') ||
      textPrefix.startsWith('<html') ||
      textPrefix.startsWith('<head') ||
      textPrefix.startsWith('<body') ||
      textPrefix.startsWith('<script')) {
    await file.delete();
    throw Exception(
      'Downloaded response is not an image/video file. The site may require browser verification.',
    );
  }
}
