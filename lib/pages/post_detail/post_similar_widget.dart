import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/downloader/downloader.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/image_zoom_page/image_zoom_page.dart';
import 'package:yande_gui/pages/post_detail/logic.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';
import 'package:yande_gui/ui/app_ui.dart';

class PostSimilarWidget extends ConsumerStatefulWidget {
  final int id;
  final double maxWidth;
  final double maxHeight;

  const PostSimilarWidget({
    super.key,
    required this.id,
    required this.maxWidth,
    required this.maxHeight,
  });

  @override
  ConsumerState createState() => _PostSimilarWidgetState();
}

class _PostSimilarWidgetState extends ConsumerState<PostSimilarWidget> {
  Widget buildPost(Post post) {
    final double calcHeight;
    final double calcWidth;

    if (post.width > post.height) {
      calcWidth = min(widget.maxWidth, post.width.toDouble());
      calcHeight = calcWidth * post.height / post.width;
    } else {
      calcHeight = min(widget.maxHeight, post.height.toDouble());
      calcWidth = calcHeight * post.width / post.height;
    }
    final imageUrl =
        post.fileUrl ?? post.jpegUrl ?? post.sampleUrl ?? post.previewUrl;
    return GestureDetector(
      onTap: () {
        final uri = Uri.tryParse(imageUrl.trim());
        if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
          EasyLoading.showError('No image URL.');
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => ImageZoomPage(
                  url: imageUrl,
                  width: post.width.toDouble(),
                  height: post.height.toDouble(),
                ),
          ),
        );
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        Downloader.instance.add(post);
      },
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: calcWidth,
            height: calcHeight >= calcWidth ? null : calcHeight,
            child: YandeImage(
              post.sampleUrl ?? post.previewUrl,
              width: calcWidth,
              height: calcHeight >= calcWidth ? null : calcHeight,
              placeholderWidget: YandeImage(post.previewUrl, width: calcWidth),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = getSimilarProvider(
      siteKey: SettingsService.siteKey,
      id: widget.id,
    );

    return switch (ref.watch(provider)) {
      AsyncData(:final value) => AppPanel(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.postDetail.similarPosts,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            for (final post in value.posts) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child:
                    post.parentId == widget.id
                        ? Text(
                          '${i18n.postDetail.parentPost}: ${widget.id}',
                          style: Theme.of(context).textTheme.labelLarge,
                        )
                        : Text(
                          '${i18n.postDetail.childPost}: ${post.id}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
              ),
              buildPost(post),
            ],
          ],
        ),
      ),
      AsyncError(:final error) => GestureDetector(
        onTap: () => ref.refresh(provider),
        behavior: HitTestBehavior.translucent,
        child: Text(i18n.generic.errorWithValue(error.toString())),
      ),
      _ => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Center(child: CupertinoActivityIndicator()),
      ),
    };
  }
}
