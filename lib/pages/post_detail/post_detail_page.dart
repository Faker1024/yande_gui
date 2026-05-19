import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yande_gui/components/translated_tag/translated_tag.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/downloader/downloader.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/image_zoom_page/image_zoom_page.dart';
import 'package:yande_gui/pages/post_detail/post_similar_widget.dart';
import 'package:yande_gui/pages/post_list/post_list_page.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';
import 'package:yande_gui/ui/app_ui.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  ConsumerState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  Post get post => widget.post;

  @override
  void dispose() {
    EasyLoading.dismiss();
    super.dispose();
  }

  static String formatIntDateTime(int timestamp) {
    final dateTime =
        DateTime.fromMillisecondsSinceEpoch(
          timestamp * 1000,
          isUtc: true,
        ).toLocal();
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> openUrl(String url) async {
    if (post.source.startsWith('https://i.pximg.net/')) {
      final list1 = post.source.split('/');
      final idPart = list1.last;
      final list2 = idPart.split('_');
      final id = list2.first;
      url = 'https://www.pixiv.net/artworks/$id';
    }

    final String? schemeUrl;
    if (url.contains('https://www.pixiv.net/artworks') ||
        url.contains('https://pixiv.net/artworks')) {
      final id = url.split('/').last;
      schemeUrl = 'pixiv://illusts/$id';
    } else if (url.contains('https://www.pixiv.net/users') ||
        url.contains('https://pixiv.net/users')) {
      final id = url.split('/').last;
      schemeUrl = 'pixiv://users/$id';
    } else {
      schemeUrl = null;
    }

    if (schemeUrl case String schemeUrl?) {
      if (Platform.isAndroid) {
        launchUrlString(
          schemeUrl,
          mode: LaunchMode.externalApplication,
        ).catchError(
          (e) => launchUrlString(url, mode: LaunchMode.externalApplication),
        );
      } else {
        if (await canLaunchUrlString(schemeUrl)) {
          launchUrlString(schemeUrl, mode: LaunchMode.externalApplication);
        } else {
          launchUrlString(url, mode: LaunchMode.externalApplication);
        }
      }
    } else {
      launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLinkRow(String label, String url, Function() onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        Clipboard.setData(ClipboardData(text: url));
        EasyLoading.showSuccess(i18n.generic.copiedWithValue(post.source));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 108,
              child: Text(label, style: theme.textTheme.bodySmall),
            ),
            Expanded(
              child: Text(
                url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMetadata() {
    final theme = Theme.of(context);
    final isLink = RegExp(
      r'^(?:http|https)://[\w\-]+(?:\.[\w\-]+)*(?::\d+)?(?:/\S*)?$',
      caseSensitive: false,
    ).hasMatch(post.source);

    return AppPanel(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  i18n.postDetail.titleWithId(post.id),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              AppPill(
                color: theme.colorScheme.secondary,
                child: Text(
                  post.rating.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Downloader.instance.add(post);
            },
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(i18n.downloads.title),
          ),
          const SizedBox(height: 14),
          Divider(color: theme.colorScheme.outlineVariant.withAlpha(120)),
          const SizedBox(height: 8),
          buildDetailRow(
            i18n.postDetail.createdAt,
            formatIntDateTime(post.createdAt),
          ),
          buildDetailRow(i18n.postDetail.author, post.author),
          if (isLink)
            buildLinkRow(
              i18n.postDetail.source,
              post.source,
              () => openUrl(post.source),
            )
          else
            buildDetailRow(i18n.postDetail.source, post.source),
          buildDetailRow(i18n.postDetail.width, '${post.width}'),
          buildDetailRow(i18n.postDetail.height, '${post.height}'),
          buildDetailRow(i18n.postDetail.score, '${post.score}'),
          buildDetailRow(
            i18n.postDetail.size,
            '${(post.fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
          ),
          buildDetailRow(
            i18n.postDetail.parent,
            post.parentId?.toString() ?? '-',
          ),
          buildDetailRow(i18n.postDetail.hasChildren, '${post.hasChildren}'),
          const SizedBox(height: 10),
          Divider(color: theme.colorScheme.outlineVariant.withAlpha(120)),
          const SizedBox(height: 12),
          Text(i18n.postDetail.tags, style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            runSpacing: 6,
            spacing: 6,
            children: [
              for (final tag in post.tags.split(' '))
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PostListPage(tags: [tag]),
                      ),
                    );
                  },
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: tag));
                    EasyLoading.showSuccess(i18n.generic.copiedWithValue(tag));
                    HapticFeedback.mediumImpact();
                  },
                  child: TranslatedTag(text: tag),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildImage({required double width, required double height}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => ImageZoomPage(
                    url:
                        post.fileUrl ??
                        post.jpegUrl ??
                        post.sampleUrl ??
                        post.previewUrl,
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withAlpha(120),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: width,
                height: height >= width ? null : height,
                child: Hero(
                  tag: post.id,
                  child: YandeImage(
                    post.sampleUrl ?? post.previewUrl,
                    width: width,
                    height: height >= width ? null : height,
                    placeholderWidget: YandeImage(
                      post.previewUrl,
                      width: width,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> buildImageList({
    required double maxWidth,
    required double maxHeight,
  }) {
    final contentMaxWidth =
        (maxWidth - 24).clamp(160.0, double.infinity).toDouble();
    final contentMaxHeight =
        (maxHeight - 24).clamp(160.0, double.infinity).toDouble();
    final double calcHeight;
    final double calcWidth;

    if (post.width > post.height) {
      calcWidth = contentMaxWidth;
      calcHeight = calcWidth * post.height / post.width;
    } else {
      calcHeight = contentMaxHeight;
      calcWidth = calcHeight * post.width / post.height;
    }
    return [
      SliverToBoxAdapter(
        child: buildImage(width: calcWidth, height: calcHeight),
      ),
      if (post.parentId != null || post.hasChildren)
        SliverToBoxAdapter(
          child: PostSimilarWidget(
            id: post.id,
            maxWidth: contentMaxWidth,
            maxHeight: contentMaxHeight,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      titleWidget: Text(i18n.postDetail.titleWithId(post.id)),
      builder: (context, horizontal) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (horizontal) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 390, child: buildMetadata()),
                  Expanded(
                    child: CustomScrollView(
                      slivers: buildImageList(
                        maxWidth: constraints.maxWidth - 390,
                        maxHeight: constraints.maxHeight,
                      ),
                    ),
                  ),
                ],
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: buildMetadata()),
                ...buildImageList(
                  maxWidth: constraints.maxWidth,
                  maxHeight: constraints.maxHeight,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
