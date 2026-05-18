import 'package:yande_gui/services/settings_service.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';

enum DownloadHistoryStatus { completed, failed }

class DownloadHistoryItem {
  final Post post;
  final String fileName;
  final String url;
  final DownloadHistoryStatus status;
  final int createdAt;
  final String? filePath;
  final String? error;

  const DownloadHistoryItem({
    required this.post,
    required this.fileName,
    required this.url,
    required this.status,
    required this.createdAt,
    this.filePath,
    this.error,
  });

  String get key => '${post.id}:$fileName';

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'fileName': fileName,
      'url': url,
      'status': status.name,
      'createdAt': createdAt,
      'filePath': filePath,
      'error': error,
      'post': _postToJson(post),
    };
  }

  static DownloadHistoryItem? fromJson(Map<String, dynamic> json) {
    final postJson = json['post'];
    if (postJson is! Map) return null;

    try {
      return DownloadHistoryItem(
        post: _postFromJson(Map<String, dynamic>.from(postJson)),
        fileName: json['fileName'] as String? ?? '',
        url: json['url'] as String? ?? '',
        status: DownloadHistoryStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => DownloadHistoryStatus.completed,
        ),
        createdAt: _asInt(json['createdAt']),
        filePath: json['filePath'] as String?,
        error: json['error'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

class DownloadHistoryService {
  DownloadHistoryService._();

  static List<DownloadHistoryItem> get items {
    return SettingsService.downloadHistory
        .map(DownloadHistoryItem.fromJson)
        .whereType<DownloadHistoryItem>()
        .toList(growable: false);
  }

  static void record({
    required Object inner,
    required String fileName,
    required String url,
    required DownloadHistoryStatus status,
    String? filePath,
    String? error,
  }) {
    if (inner is! Post) return;

    SettingsService.upsertDownloadHistory(
      DownloadHistoryItem(
        post: inner,
        fileName: fileName,
        url: url,
        status: status,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        filePath: filePath,
        error: error,
      ).toJson(),
    );
  }

  static void remove(DownloadHistoryItem item) {
    SettingsService.removeDownloadHistory(item.key);
  }

  static void clear() {
    SettingsService.clearDownloadHistory();
  }
}

Map<String, dynamic> _postToJson(Post post) {
  return {
    'id': _asInt(post.id),
    'tags': post.tags,
    'createdAt': _asInt(post.createdAt),
    'updatedAt': _asInt(post.updatedAt),
    'creatorId': _asNullableInt(post.creatorId),
    'author': post.author,
    'change': _asInt(post.change),
    'source': post.source,
    'score': _asInt(post.score),
    'md5': post.md5,
    'fileSize': _asInt(post.fileSize),
    'fileExt': post.fileExt,
    'fileUrl': post.fileUrl,
    'isShownInIndex': post.isShownInIndex,
    'previewUrl': post.previewUrl,
    'previewWidth': _asInt(post.previewWidth),
    'previewHeight': _asInt(post.previewHeight),
    'actualPreviewWidth': _asInt(post.actualPreviewWidth),
    'actualPreviewHeight': _asInt(post.actualPreviewHeight),
    'sampleUrl': post.sampleUrl,
    'sampleWidth': _asInt(post.sampleWidth),
    'sampleHeight': _asInt(post.sampleHeight),
    'sampleFileSize': _asInt(post.sampleFileSize),
    'jpegUrl': post.jpegUrl,
    'jpegWidth': _asInt(post.jpegWidth),
    'jpegHeight': _asInt(post.jpegHeight),
    'jpegFileSize': _asInt(post.jpegFileSize),
    'rating': post.rating,
    'isRatingLocked': post.isRatingLocked,
    'hasChildren': post.hasChildren,
    'parentId': _asNullableInt(post.parentId),
    'status': post.status,
    'isPending': post.isPending,
    'width': _asInt(post.width),
    'height': _asInt(post.height),
    'isHeld': post.isHeld,
    'isNoteLocked': post.isNoteLocked,
  };
}

Post _postFromJson(Map<String, dynamic> json) {
  return Post(
    id: _asInt(json['id']),
    tags: json['tags'] as String? ?? '',
    createdAt: _asInt(json['createdAt']),
    updatedAt: _asInt(json['updatedAt']),
    creatorId: _asNullableInt(json['creatorId']),
    author: json['author'] as String? ?? '',
    change: _asInt(json['change']),
    source: json['source'] as String? ?? '',
    score: _asInt(json['score']),
    md5: json['md5'] as String? ?? '',
    fileSize: _asInt(json['fileSize']),
    fileExt: json['fileExt'] as String? ?? '',
    fileUrl: json['fileUrl'] as String?,
    isShownInIndex: json['isShownInIndex'] as bool? ?? true,
    previewUrl: json['previewUrl'] as String? ?? '',
    previewWidth: _asInt(json['previewWidth']),
    previewHeight: _asInt(json['previewHeight']),
    actualPreviewWidth: _asInt(json['actualPreviewWidth']),
    actualPreviewHeight: _asInt(json['actualPreviewHeight']),
    sampleUrl: json['sampleUrl'] as String?,
    sampleWidth: _asInt(json['sampleWidth']),
    sampleHeight: _asInt(json['sampleHeight']),
    sampleFileSize: _asInt(json['sampleFileSize']),
    jpegUrl: json['jpegUrl'] as String?,
    jpegWidth: _asInt(json['jpegWidth']),
    jpegHeight: _asInt(json['jpegHeight']),
    jpegFileSize: _asInt(json['jpegFileSize']),
    rating: json['rating'] as String? ?? '',
    isRatingLocked: json['isRatingLocked'] as bool? ?? false,
    hasChildren: json['hasChildren'] as bool? ?? false,
    parentId: _asNullableInt(json['parentId']),
    status: json['status'] as String? ?? '',
    isPending: json['isPending'] as bool? ?? false,
    width: _asInt(json['width']),
    height: _asInt(json['height']),
    isHeld: json['isHeld'] as bool? ?? false,
    isNoteLocked: json['isNoteLocked'] as bool? ?? false,
  );
}

int _asInt(Object? value) {
  return switch (value) {
    int value => value,
    BigInt value => value.toInt(),
    num value => value.toInt(),
    String value => int.tryParse(value) ?? 0,
    _ => 0,
  };
}

int? _asNullableInt(Object? value) {
  if (value == null) return null;
  return _asInt(value);
}
