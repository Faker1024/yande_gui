import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yande_gui/services/booru_site_service.dart';
import 'package:yande_gui/src/rust/yande/model/similar.dart';

part 'logic.g.dart';

@riverpod
Future<Similar> getSimilar(
  Ref ref, {
  required String siteKey,
  required int id,
}) async {
  final similar = await BooruSiteService.getSimilar(
    siteKey: siteKey,
    postId: id,
  );
  return similar;
}
