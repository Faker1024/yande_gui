// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PostList)
const postListProvider = PostListFamily._();

final class PostListProvider
    extends $NotifierProvider<PostList, PostListState> {
  const PostListProvider._({
    required PostListFamily super.from,
    required (
      Type, {
      String siteKey,
      List<String> tags,
      PostListMode mode,
      PopularScale popularScale,
      DateTime popularDate,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'postListProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postListHash();

  @override
  String toString() {
    return r'postListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PostList create() => PostList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostListState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PostListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postListHash() => r'3567d2f3fd91818bdbd27ad8728bdf7040c50233';

final class PostListFamily extends $Family
    with
        $ClassFamilyOverride<
          PostList,
          PostListState,
          PostListState,
          PostListState,
          (
            Type, {
            String siteKey,
            List<String> tags,
            PostListMode mode,
            PopularScale popularScale,
            DateTime popularDate,
          })
        > {
  const PostListFamily._()
    : super(
        retry: null,
        name: r'postListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  PostListProvider call(
    Type type, {
    required String siteKey,
    required List<String> tags,
    PostListMode mode = PostListMode.recent,
    PopularScale popularScale = PopularScale.day,
    required DateTime popularDate,
  }) => PostListProvider._(
    argument: (
      type,
      siteKey: siteKey,
      tags: tags,
      mode: mode,
      popularScale: popularScale,
      popularDate: popularDate,
    ),
    from: this,
  );

  @override
  String toString() => r'postListProvider';
}

abstract class _$PostList extends $Notifier<PostListState> {
  late final _$args =
      ref.$arg
          as (
            Type, {
            String siteKey,
            List<String> tags,
            PostListMode mode,
            PopularScale popularScale,
            DateTime popularDate,
          });
  Type get type => _$args.$1;
  String get siteKey => _$args.siteKey;
  List<String> get tags => _$args.tags;
  PostListMode get mode => _$args.mode;
  PopularScale get popularScale => _$args.popularScale;
  DateTime get popularDate => _$args.popularDate;

  PostListState build(
    Type type, {
    required String siteKey,
    required List<String> tags,
    PostListMode mode = PostListMode.recent,
    PopularScale popularScale = PopularScale.day,
    required DateTime popularDate,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      _$args.$1,
      siteKey: _$args.siteKey,
      tags: _$args.tags,
      mode: _$args.mode,
      popularScale: _$args.popularScale,
      popularDate: _$args.popularDate,
    );
    final ref = this.ref as $Ref<PostListState, PostListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PostListState, PostListState>,
              PostListState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
