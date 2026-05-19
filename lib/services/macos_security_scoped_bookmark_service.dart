import 'dart:io';

import 'package:flutter/services.dart';

class MacOSDirectoryGrant {
  final String path;
  final String bookmark;

  const MacOSDirectoryGrant({required this.path, required this.bookmark});
}

class MacOSSecurityScopedBookmarkService {
  MacOSSecurityScopedBookmarkService._();

  static const _channel = MethodChannel(
    'io.github.normalllll.yandegui/security_scoped_bookmark',
  );

  static Future<MacOSDirectoryGrant?> pickDirectory() async {
    if (!Platform.isMacOS) return null;

    final result = await _channel.invokeMapMethod<String, Object?>(
      'pickDirectory',
    );
    if (result == null) return null;

    final path = result['path'] as String?;
    final bookmark = result['bookmark'] as String?;
    if (path == null || bookmark == null) return null;

    return MacOSDirectoryGrant(path: path, bookmark: bookmark);
  }

  static Future<String?> startAccessing(String? bookmark) async {
    if (!Platform.isMacOS || bookmark == null || bookmark.isEmpty) {
      return null;
    }

    final result = await _channel.invokeMapMethod<String, Object?>(
      'startAccessing',
      {'bookmark': bookmark},
    );
    return result?['path'] as String?;
  }

  static Future<void> stopAccessing(String? path) async {
    if (!Platform.isMacOS || path == null || path.isEmpty) return;

    await _channel.invokeMethod<void>('stopAccessing', {'path': path});
  }
}
