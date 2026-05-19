import 'dart:convert';
import 'dart:io';

import 'package:yande_gui/global.dart';
import 'package:yande_gui/services/dns_service.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:yande_gui/src/rust/api/yande_client.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';
import 'package:yande_gui/src/rust/yande/model/similar.dart';

enum BooruSite {
  yande(key: 'yande', displayName: 'yande.re', baseUrl: 'https://yande.re'),
  konachan(
    key: 'konachan',
    displayName: 'Konachan',
    baseUrl: 'https://konachan.com',
  ),
  danbooru(
    key: 'danbooru',
    displayName: 'Danbooru',
    baseUrl: 'https://danbooru.donmai.us',
  );

  const BooruSite({
    required this.key,
    required this.displayName,
    required this.baseUrl,
  });

  final String key;
  final String displayName;
  final String baseUrl;

  Uri get postPageUri => Uri.parse('$baseUrl/post');

  Uri get popularPageUri => switch (this) {
    BooruSite.yande => Uri.parse('$baseUrl/post/popular_recent'),
    BooruSite.konachan => Uri.parse('$baseUrl/post/popular_recent'),
    BooruSite.danbooru => Uri.parse('$baseUrl/explore/posts/popular'),
  };

  static BooruSite fromKey(String? key) {
    return BooruSite.values.firstWhere(
      (site) => site.key == key,
      orElse: () => BooruSite.yande,
    );
  }

  static BooruSite? fromUrl(String url) {
    final host = Uri.tryParse(url)?.host;
    if (host == null) return null;
    if (host == 'yande.re' || host.endsWith('.yande.re')) {
      return BooruSite.yande;
    }
    if (host == 'konachan.com' ||
        host.endsWith('.konachan.com') ||
        host == 'konachan.net' ||
        host.endsWith('.konachan.net')) {
      return BooruSite.konachan;
    }
    if (host == 'danbooru.donmai.us' ||
        host.endsWith('.danbooru.donmai.us') ||
        host == 'cdn.donmai.us' ||
        host.endsWith('.cdn.donmai.us')) {
      return BooruSite.danbooru;
    }
    return null;
  }
}

enum PopularScale { day, week, month, year }

class BooruSiteService {
  BooruSiteService._();

  static BooruSite get current => BooruSite.fromKey(SettingsService.siteKey);

  static Future<void> configureClients({required bool fetchDns}) async {
    StringArray3? ips;

    if (current == BooruSite.yande && SettingsService.prefetchDns) {
      try {
        final dns = fetchDns ? await DnsService.fetchDns() : realIps;
        realIps = dns;
        ips = dns != null ? StringArray3(dns) : null;
      } catch (_) {
        ips = null;
      }
    }

    setYandeClient(YandeClient(ips: ips, forLargeFile: false));
    setDownloadClient(YandeClient(ips: null, forLargeFile: true));
  }

  static Future<List<Post>> getPosts({
    required String siteKey,
    required List<String> tags,
    required int limit,
    required int page,
  }) {
    return switch (BooruSite.fromKey(siteKey)) {
      BooruSite.yande => yandeClient.getPosts(
        tags: tags,
        limit: limit,
        page: page,
      ),
      BooruSite.konachan => _KonachanApi.getPosts(
        tags: tags,
        limit: limit,
        page: page,
      ),
      BooruSite.danbooru => _DanbooruApi.getPosts(
        tags: tags,
        limit: limit,
        page: page,
      ),
    };
  }

  static Future<List<Post>> getPopularPosts({
    required String siteKey,
    required PopularScale scale,
    required DateTime date,
    required int limit,
    required int page,
  }) {
    return switch (BooruSite.fromKey(siteKey)) {
      BooruSite.yande => _YandeApi.getPopularPosts(
        scale: scale,
        date: date,
        limit: limit,
        page: page,
      ),
      BooruSite.konachan => _KonachanApi.getPopularPosts(
        scale: scale,
        date: date,
        limit: limit,
        page: page,
      ),
      BooruSite.danbooru => _DanbooruApi.getPopularPosts(
        scale: scale,
        date: date,
        limit: limit,
        page: page,
      ),
    };
  }

  static Future<Similar> getSimilar({
    required String siteKey,
    required int postId,
  }) {
    return switch (BooruSite.fromKey(siteKey)) {
      BooruSite.yande => yandeClient.getSimilar(postId: postId),
      BooruSite.konachan => _KonachanApi.getSimilar(postId: postId),
      BooruSite.danbooru => _DanbooruApi.getSimilar(postId: postId),
    };
  }
}

class _YandeApi {
  _YandeApi._();

  static final HttpClient _client =
      HttpClient()
        ..userAgent =
            'Yande GUI/${Global.appVersion} (https://github.com/normalllll/yande_gui)';

  static Future<List<Post>> getPopularPosts({
    required PopularScale scale,
    required DateTime date,
    required int limit,
    required int page,
  }) async {
    if (page > 1) return const [];

    if (scale == PopularScale.year) {
      return _getYearPopularPosts(
        date: date,
        limit: limit,
        fetchMonth:
            (month) => _getPopularPostsByPeriod(
              path: '/post/popular_by_month.json',
              date: DateTime(date.year, month),
              limit: limit,
            ),
      );
    }

    return _getPopularPostsByPeriod(
      path: _pathForScale(scale),
      date: date,
      limit: limit,
    );
  }

  static Future<List<Post>> _getPopularPostsByPeriod({
    required String path,
    required DateTime date,
    required int limit,
  }) async {
    final json = await _getJson(
      Uri.https('yande.re', path, {
        ..._moebooruDateQuery(date),
        'limit': limit.toString(),
      }),
    );

    if (json is! List) {
      throw const FormatException('Unexpected yande.re popular response.');
    }

    return json
        .whereType<Map>()
        .map((item) => _postFromApiJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static String _pathForScale(PopularScale scale) {
    return switch (scale) {
      PopularScale.day => '/post/popular_by_day.json',
      PopularScale.week => '/post/popular_by_week.json',
      PopularScale.month => '/post/popular_by_month.json',
      PopularScale.year => '/post/popular_by_month.json',
    };
  }

  static Future<dynamic> _getJson(Uri uri) async {
    final request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'yande.re request failed with status ${response.statusCode}.',
        uri: uri,
      );
    }

    return jsonDecode(body);
  }
}

class _KonachanApi {
  _KonachanApi._();

  static const _hosts = ['konachan.com', 'konachan.net'];

  static final HttpClient _client =
      HttpClient()
        ..userAgent =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome Safari';

  static Future<List<Post>> getPosts({
    required List<String> tags,
    required int limit,
    required int page,
  }) async {
    final json = await _getJsonWithFallback('/post.json', {
      if (tags.isNotEmpty) 'tags': tags.join(' '),
      'limit': limit.toString(),
      'page': page.toString(),
    });

    if (json is! List) {
      throw const FormatException('Unexpected Konachan post response.');
    }

    return json
        .whereType<Map>()
        .map((item) => _postFromApiJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static Future<List<Post>> getPopularPosts({
    required PopularScale scale,
    required DateTime date,
    required int limit,
    required int page,
  }) async {
    if (page > 1) return const [];

    if (scale == PopularScale.year) {
      return _getYearPopularPosts(
        date: date,
        limit: limit,
        fetchMonth:
            (month) => _getPopularPostsByPeriod(
              path: '/post/popular_by_month.json',
              date: DateTime(date.year, month),
              limit: limit,
            ),
      );
    }

    return _getPopularPostsByPeriod(
      path: _pathForScale(scale),
      date: date,
      limit: limit,
    );
  }

  static Future<List<Post>> _getPopularPostsByPeriod({
    required String path,
    required DateTime date,
    required int limit,
  }) async {
    final json = await _getJsonWithFallback(path, {
      ..._moebooruDateQuery(date),
      'limit': limit.toString(),
    });

    if (json is! List) {
      throw const FormatException('Unexpected Konachan popular response.');
    }

    return json
        .whereType<Map>()
        .map((item) => _postFromApiJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static String _pathForScale(PopularScale scale) {
    return switch (scale) {
      PopularScale.day => '/post/popular_by_day.json',
      PopularScale.week => '/post/popular_by_week.json',
      PopularScale.month => '/post/popular_by_month.json',
      PopularScale.year => '/post/popular_by_month.json',
    };
  }

  static Future<Similar> getSimilar({required int postId}) async {
    final json = await _getJsonWithFallback('/post/similar.json', {
      'id': postId.toString(),
    });

    if (json is! Map) {
      throw const FormatException('Unexpected Konachan similar response.');
    }

    final map = Map<String, dynamic>.from(json);
    final posts = (map['posts'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _postFromApiJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final sourceJson = map['source'];

    return Similar(
      posts: posts,
      source:
          sourceJson is Map
              ? _postFromApiJson(Map<String, dynamic>.from(sourceJson))
              : Post(
                id: postId,
                tags: '',
                createdAt: 0,
                updatedAt: 0,
                author: '',
                change: 0,
                source: '',
                score: 0,
                md5: '',
                fileSize: 0,
                fileExt: '',
                isShownInIndex: true,
                previewUrl: '',
                previewWidth: 0,
                previewHeight: 0,
                actualPreviewWidth: 0,
                actualPreviewHeight: 0,
                sampleWidth: 0,
                sampleHeight: 0,
                sampleFileSize: 0,
                jpegWidth: 0,
                jpegHeight: 0,
                jpegFileSize: 0,
                rating: '',
                hasChildren: false,
                status: '',
                isPending: false,
                width: 0,
                height: 0,
                isHeld: false,
                isNoteLocked: false,
                isRatingLocked: false,
              ),
    );
  }

  static Future<dynamic> _getJsonWithFallback(
    String path,
    Map<String, String> queryParameters,
  ) async {
    Object? lastError;

    for (final host in _hosts) {
      try {
        return await _getJson(Uri.https(host, path, queryParameters));
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? StateError('Konachan request failed.');
  }

  static Future<dynamic> _getJson(Uri uri) async {
    final request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Konachan request failed with status ${response.statusCode}.',
        uri: uri,
      );
    }

    final contentType = response.headers.contentType?.mimeType;
    if (contentType != null && !contentType.contains('json')) {
      throw HttpException(
        'Konachan did not return JSON. The site may be asking for a browser verification.',
        uri: uri,
      );
    }

    return jsonDecode(body);
  }
}

class _DanbooruApi {
  _DanbooruApi._();

  static final HttpClient _client =
      HttpClient()
        ..userAgent =
            'Yande GUI/${Global.appVersion} (https://github.com/normalllll/yande_gui)';

  static Future<List<Post>> getPosts({
    required List<String> tags,
    required int limit,
    required int page,
  }) async {
    final json = await _getJson(
      Uri.https('danbooru.donmai.us', '/posts.json', {
        if (tags.isNotEmpty) 'tags': tags.join(' '),
        'limit': limit.toString(),
        'page': page.toString(),
      }),
    );

    if (json is! List) {
      throw const FormatException('Unexpected Danbooru post response.');
    }

    return json
        .whereType<Map>()
        .map((item) => _postFromDanbooruJson(Map<String, dynamic>.from(item)))
        .where(_hasImageUrl)
        .toList(growable: false);
  }

  static Future<List<Post>> getPopularPosts({
    required PopularScale scale,
    required DateTime date,
    required int limit,
    required int page,
  }) async {
    if (page > 1) return const [];

    final json = await _getJson(
      Uri.https('danbooru.donmai.us', '/explore/posts/popular.json', {
        'scale': scale.name,
        'date': _formatIsoDate(date),
        'limit': limit.toString(),
      }),
    );

    if (json is! List) {
      throw const FormatException('Unexpected Danbooru popular response.');
    }

    return json
        .whereType<Map>()
        .map((item) => _postFromDanbooruJson(Map<String, dynamic>.from(item)))
        .where(_hasImageUrl)
        .toList(growable: false);
  }

  static Future<Similar> getSimilar({required int postId}) async {
    final source = await getPost(postId);
    final posts = <Post>[];

    if (source.parentId case final parentId?) {
      try {
        final parent = await getPost(parentId);
        if (_hasImageUrl(parent)) {
          posts.add(parent);
        }
      } catch (_) {}
    }

    try {
      posts.addAll(
        await getPosts(tags: ['parent:$postId'], limit: 20, page: 1),
      );
    } catch (_) {}

    return Similar(posts: posts, source: source);
  }

  static Future<Post> getPost(int postId) async {
    final json = await _getJson(
      Uri.https('danbooru.donmai.us', '/posts/$postId.json'),
    );

    if (json is! Map) {
      throw const FormatException('Unexpected Danbooru post response.');
    }

    return _postFromDanbooruJson(Map<String, dynamic>.from(json));
  }

  static Future<dynamic> _getJson(Uri uri) async {
    final request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Danbooru request failed with status ${response.statusCode}.',
        uri: uri,
      );
    }

    return jsonDecode(body);
  }
}

Post _postFromApiJson(Map<String, dynamic> json) {
  final previewWidth = _asInt(json['preview_width'] ?? json['previewWidth']);
  final previewHeight = _asInt(json['preview_height'] ?? json['previewHeight']);
  final createdAt = _asInt(json['created_at'] ?? json['createdAt']);
  final fileUrl = json['file_url'] as String? ?? json['fileUrl'] as String?;
  final jpegUrl = json['jpeg_url'] as String? ?? json['jpegUrl'] as String?;
  final previewUrl =
      json['preview_url'] as String? ?? json['previewUrl'] as String? ?? '';

  return Post(
    id: _asInt(json['id']),
    tags: json['tags'] as String? ?? '',
    createdAt: createdAt,
    updatedAt: _asInt(json['updated_at'] ?? json['updatedAt'] ?? createdAt),
    creatorId: _asNullableInt(json['creator_id'] ?? json['creatorId']),
    author: json['author'] as String? ?? '',
    change: _asInt(json['change']),
    source: json['source'] as String? ?? '',
    score: _asInt(json['score']),
    md5: json['md5'] as String? ?? '',
    fileSize: _asInt(json['file_size'] ?? json['fileSize']),
    fileExt: json['file_ext'] as String? ?? _fileExtFromUrl(fileUrl ?? jpegUrl),
    fileUrl: fileUrl,
    isShownInIndex:
        json['is_shown_in_index'] as bool? ??
        json['isShownInIndex'] as bool? ??
        true,
    previewUrl: previewUrl,
    previewWidth: previewWidth,
    previewHeight: previewHeight,
    actualPreviewWidth: _asInt(
      json['actual_preview_width'] ??
          json['actualPreviewWidth'] ??
          previewWidth,
    ),
    actualPreviewHeight: _asInt(
      json['actual_preview_height'] ??
          json['actualPreviewHeight'] ??
          previewHeight,
    ),
    sampleUrl: json['sample_url'] as String? ?? json['sampleUrl'] as String?,
    sampleWidth: _asInt(json['sample_width'] ?? json['sampleWidth']),
    sampleHeight: _asInt(json['sample_height'] ?? json['sampleHeight']),
    sampleFileSize: _asInt(json['sample_file_size'] ?? json['sampleFileSize']),
    jpegUrl: jpegUrl,
    jpegWidth: _asInt(json['jpeg_width'] ?? json['jpegWidth']),
    jpegHeight: _asInt(json['jpeg_height'] ?? json['jpegHeight']),
    jpegFileSize: _asInt(json['jpeg_file_size'] ?? json['jpegFileSize']),
    rating: json['rating'] as String? ?? '',
    isRatingLocked:
        json['is_rating_locked'] as bool? ??
        json['isRatingLocked'] as bool? ??
        false,
    hasChildren:
        json['has_children'] as bool? ?? json['hasChildren'] as bool? ?? false,
    parentId: _asNullableInt(json['parent_id'] ?? json['parentId']),
    status: json['status'] as String? ?? '',
    isPending:
        json['is_pending'] as bool? ?? json['isPending'] as bool? ?? false,
    width: _asInt(json['width']),
    height: _asInt(json['height']),
    isHeld: json['is_held'] as bool? ?? json['isHeld'] as bool? ?? false,
    isNoteLocked:
        json['is_note_locked'] as bool? ??
        json['isNoteLocked'] as bool? ??
        false,
  );
}

Post _postFromDanbooruJson(Map<String, dynamic> json) {
  final id = _asInt(json['id']);
  final width = _asInt(json['image_width']);
  final height = _asInt(json['image_height']);
  final previewUrl = _absoluteDanbooruUrl(json['preview_file_url'] as String?);
  final sampleUrl = _absoluteDanbooruUrl(
    json['large_file_url'] as String? ?? json['file_url'] as String?,
  );
  final fileUrl = _absoluteDanbooruUrl(json['file_url'] as String?);
  final jpegUrl = _absoluteDanbooruUrl(
    json['large_file_url'] as String? ?? json['file_url'] as String?,
  );
  final createdAt = _asTimestamp(json['created_at']);
  final updatedAt = _asTimestamp(json['updated_at']) ?? createdAt;
  final isDeleted = json['is_deleted'] as bool? ?? false;

  return Post(
    id: id,
    tags: json['tag_string'] as String? ?? '',
    createdAt: createdAt ?? 0,
    updatedAt: updatedAt ?? 0,
    creatorId: _asNullableInt(json['uploader_id']),
    author: '',
    change: _asInt(json['updated_at']) == 0 ? id : _asInt(json['updated_at']),
    source: json['source'] as String? ?? '',
    score: _asInt(json['score']),
    md5: json['md5'] as String? ?? '',
    fileSize: _asInt(json['file_size']),
    fileExt: json['file_ext'] as String? ?? _fileExtFromUrl(fileUrl ?? jpegUrl),
    fileUrl: fileUrl,
    isShownInIndex: !isDeleted,
    previewUrl: previewUrl ?? sampleUrl ?? fileUrl ?? '',
    previewWidth: width > 0 && height > 0 ? 150 : 0,
    previewHeight: width > 0 && height > 0 ? (height * 150 / width).round() : 0,
    actualPreviewWidth: width > 0 && height > 0 ? 300 : 0,
    actualPreviewHeight:
        width > 0 && height > 0 ? (height * 300 / width).round() : 0,
    sampleUrl: sampleUrl,
    sampleWidth: width,
    sampleHeight: height,
    sampleFileSize: _asInt(json['file_size']),
    jpegUrl: jpegUrl,
    jpegWidth: width,
    jpegHeight: height,
    jpegFileSize: _asInt(json['file_size']),
    rating: json['rating'] as String? ?? '',
    isRatingLocked: false,
    hasChildren:
        json['has_children'] as bool? ??
        json['has_visible_children'] as bool? ??
        false,
    parentId: _asNullableInt(json['parent_id']),
    status: isDeleted ? 'deleted' : 'active',
    isPending: json['is_pending'] as bool? ?? false,
    width: width,
    height: height,
    isHeld: json['is_flagged'] as bool? ?? false,
    isNoteLocked: false,
  );
}

String _fileExtFromUrl(String? url) {
  final path = Uri.tryParse(url ?? '')?.path;
  if (path == null) return 'jpg';
  final dotIndex = path.lastIndexOf('.');
  if (dotIndex < 0 || dotIndex == path.length - 1) return 'jpg';
  return path.substring(dotIndex + 1).toLowerCase();
}

String? _absoluteDanbooruUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('/')) return 'https://danbooru.donmai.us$url';
  return url;
}

bool _hasImageUrl(Post post) {
  return _isHttpUrl(post.previewUrl) ||
      _isHttpUrl(post.sampleUrl) ||
      _isHttpUrl(post.jpegUrl) ||
      _isHttpUrl(post.fileUrl);
}

Map<String, String> _moebooruDateQuery(DateTime date) {
  return {
    'year': date.year.toString(),
    'month': date.month.toString(),
    'day': date.day.toString(),
  };
}

Future<List<Post>> _getYearPopularPosts({
  required DateTime date,
  required int limit,
  required Future<List<Post>> Function(int month) fetchMonth,
}) async {
  final now = DateTime.now();
  final lastMonth = date.year == now.year ? now.month : 12;
  if (date.year > now.year) return const [];

  final monthLists = await Future.wait([
    for (var month = 1; month <= lastMonth; month++)
      fetchMonth(month).catchError((_) => <Post>[]),
  ]);

  final seen = <int>{};
  final posts = [
    for (final list in monthLists)
      for (final post in list)
        if (seen.add(post.id)) post,
  ];

  posts.sort((a, b) {
    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;
    return b.id.compareTo(a.id);
  });

  return posts.take(limit).toList(growable: false);
}

String _formatIsoDate(DateTime date) {
  return [
    date.year.toString().padLeft(4, '0'),
    date.month.toString().padLeft(2, '0'),
    date.day.toString().padLeft(2, '0'),
  ].join('-');
}

bool _isHttpUrl(String? url) {
  final uri = Uri.tryParse(url?.trim() ?? '');
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

int? _asTimestamp(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final numeric = int.tryParse(value);
    if (numeric != null) return numeric;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return parsed.millisecondsSinceEpoch ~/ 1000;
  }
  return null;
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
