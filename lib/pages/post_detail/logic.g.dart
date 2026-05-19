// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getSimilar)
const getSimilarProvider = GetSimilarFamily._();

final class GetSimilarProvider
    extends $FunctionalProvider<AsyncValue<Similar>, Similar, FutureOr<Similar>>
    with $FutureModifier<Similar>, $FutureProvider<Similar> {
  const GetSimilarProvider._({
    required GetSimilarFamily super.from,
    required ({String siteKey, int id}) super.argument,
  }) : super(
         retry: null,
         name: r'getSimilarProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getSimilarHash();

  @override
  String toString() {
    return r'getSimilarProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Similar> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Similar> create(Ref ref) {
    final argument = this.argument as ({String siteKey, int id});
    return getSimilar(ref, siteKey: argument.siteKey, id: argument.id);
  }

  @override
  bool operator ==(Object other) {
    return other is GetSimilarProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getSimilarHash() => r'9a3ee7c46d510cbc1aeb5c8617b11684c4435ebf';

final class GetSimilarFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Similar>,
          ({String siteKey, int id})
        > {
  const GetSimilarFamily._()
    : super(
        retry: null,
        name: r'getSimilarProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetSimilarProvider call({required String siteKey, required int id}) =>
      GetSimilarProvider._(argument: (siteKey: siteKey, id: id), from: this);

  @override
  String toString() => r'getSimilarProvider';
}
