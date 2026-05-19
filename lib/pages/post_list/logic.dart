import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yande_gui/data_list_source.dart';
import 'package:yande_gui/services/booru_site_service.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';

part 'logic.g.dart';

enum PostListMode { recent, popular }

class PostListState {
  final List<String> tags;

  final PostListSource source;

  PostListState({required this.tags, required this.source});

  PostListState copyWith({List<String>? tags, PostListSource? source}) {
    return PostListState(
      tags: tags ?? this.tags,
      source: source ?? this.source,
    );
  }
}

class PostListSource extends DataListSource<Post> {
  final String siteKey;
  final List<String> tags;
  final PostListMode mode;
  final PopularScale popularScale;
  final DateTime popularDate;

  PostListSource({
    required this.siteKey,
    this.tags = const [],
    this.mode = PostListMode.recent,
    this.popularScale = PopularScale.day,
    required this.popularDate,
  });

  @override
  Future<List<Post>> fetchList(int page, int limit) {
    return switch (mode) {
      PostListMode.recent => BooruSiteService.getPosts(
        siteKey: siteKey,
        tags: tags,
        limit: limit,
        page: page,
      ),
      PostListMode.popular => BooruSiteService.getPopularPosts(
        siteKey: siteKey,
        scale: popularScale,
        date: popularDate,
        limit: limit,
        page: page,
      ),
    };
  }
}

@Riverpod(keepAlive: true)
class PostList extends _$PostList {
  @override
  PostListState build(
    Type type, {
    required String siteKey,
    required List<String> tags,
    PostListMode mode = PostListMode.recent,
    PopularScale popularScale = PopularScale.day,
    required DateTime popularDate,
  }) {
    return PostListState(
      tags: tags,
      source: PostListSource(
        siteKey: siteKey,
        tags: tags,
        mode: mode,
        popularScale: popularScale,
        popularDate: popularDate,
      ),
    );
  }

  void onTagsChanged(List<String> tags) {
    state.source.clear();
    state = state.copyWith(
      tags: tags,
      source: PostListSource(
        siteKey: siteKey,
        tags: tags,
        mode: mode,
        popularScale: popularScale,
        popularDate: popularDate,
      ),
    );
    state.source.refresh(true);
  }
}
