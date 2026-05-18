import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:yande_gui/components/loading_more_indicator/loading_more_indicator.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/downloader/downloader.dart';
import 'package:yande_gui/enums.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/post_detail/post_detail_page.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

import 'logic.dart';

class PostListPage extends ConsumerStatefulWidget {
  final List<String>? tags;

  const PostListPage({super.key, this.tags});

  @override
  ConsumerState createState() => _PostListPageState();
}

const double _kActivityIndicatorRadius = 14.0;

class _PostListPageState extends ConsumerState<PostListPage> {
  late final provider = postListProvider(runtimeType, tags: widget.tags ?? []);

  bool get needTopPadding => widget.tags == null;

  Widget buildRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    final double percentageComplete = clampDouble(
      pulledExtent / refreshTriggerPullDistance,
      0.0,
      1.0,
    );

    // Place the indicator at the top of the sliver that opens up. We're using a
    // Stack/Positioned widget because the CupertinoActivityIndicator does some
    // internal translations based on the current size (which grows as the user drags)
    // that makes Padding calculations difficult. Rather than be reliant on the
    // internal implementation of the activity indicator, the Positioned widget allows
    // us to be explicit where the widget gets placed. The indicator should appear
    // over the top of the dragged widget, hence the use of Clip.none.

    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          top: needTopPadding ? MediaQuery.of(context).padding.top + 4 : 0,
        ),
        child: _buildIndicatorForRefreshState(
          refreshState,
          _kActivityIndicatorRadius,
          percentageComplete,
        ),
      ),
    );
  }

  static Widget _buildIndicatorForRefreshState(
    RefreshIndicatorMode refreshState,
    double radius,
    double percentageComplete,
  ) {
    switch (refreshState) {
      case RefreshIndicatorMode.drag:
        // While we're dragging, we draw individual ticks of the spinner while simultaneously
        // easing the opacity in. The opacity curve values here were derived using
        // Xcode through inspecting a native app running on iOS 13.5.
        const Curve opacityCurve = Interval(0.0, 0.35, curve: Curves.easeInOut);
        return Opacity(
          opacity: opacityCurve.transform(percentageComplete),
          child: CupertinoActivityIndicator.partiallyRevealed(
            radius: radius,
            progress: percentageComplete,
          ),
        );
      case RefreshIndicatorMode.armed:
      case RefreshIndicatorMode.refresh:
        // Once we're armed or performing the refresh, we just show the normal spinner.
        return CupertinoActivityIndicator(radius: radius);
      case RefreshIndicatorMode.done:
        // When the user lets go, the standard transition is to shrink the spinner.
        return CupertinoActivityIndicator(radius: radius * percentageComplete);
      case RefreshIndicatorMode.inactive:
        // Anything else doesn't show anything.
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final targetWidth = isDesktop ? 220 : 160;

    final columnsMax = (screenWidth ~/ targetWidth).clamp(1, 12).toInt();

    return AutoScaffold(
      topSafeArea: false,
      builder: (context, horizontal) {
        return LoadingMoreCustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            if (widget.tags != null)
              SliverAppBar(
                floating: isMobile || widget.tags == null,
                snap: isMobile,
                pinned: isDesktop && widget.tags != null,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                backgroundColor: theme.scaffoldBackgroundColor,
                title: switch (widget.tags) {
                  final tags? => Text(
                    i18n.postList.titleWithTags(tags.join(' ')),
                  ),
                  _ => Text(i18n.postList.title),
                },
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(
                    color: theme.colorScheme.outlineVariant.withAlpha(120),
                    height: 1,
                  ),
                ),
              ),
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                await state.source.refresh(false, false);
              },
              refreshIndicatorExtent: 25,
              builder: buildRefreshIndicator,
            ),
            if (needTopPadding)
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top),
              ),
            LoadingMoreSliverList(
              SliverListConfig(
                extendedListDelegate:
                    SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          SettingsService.waterfallColumns ?? columnsMax,
                    ),
                itemBuilder: (BuildContext context, item, int index) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      const padding = 5.0;
                      final width = constraints.maxWidth - padding * 2;
                      final height =
                          (item.height * width / item.width) - padding * 2;
                      final lightOverlay = theme.brightness == Brightness.light;
                      final overlayColor =
                          lightOverlay
                              ? Colors.white.withAlpha(225)
                              : const Color(0xFF251C27).withAlpha(200);
                      final overlayTextColor =
                          lightOverlay
                              ? theme.colorScheme.onSurface
                              : Colors.white;

                      return Padding(
                        padding: const EdgeInsets.all(padding),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => PostDetailPage(post: item),
                                ),
                              );
                            },
                            onLongPress: () {
                              HapticFeedback.mediumImpact();
                              Downloader.instance.add(item);
                            },
                            child: Stack(
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant
                                          .withAlpha(120),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: YandeImage(
                                      item.previewUrl,
                                      width: width,
                                      height: height,
                                      imageBuilder: (child) {
                                        return Hero(
                                          tag: item.id,
                                          child: child,
                                        ).animate().fade(duration: 180.ms);
                                      },
                                    ),
                                  ),
                                ),
                                if (item.parentId != null || item.hasChildren)
                                  Positioned(
                                    right: 7,
                                    top: 7,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: overlayColor,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: Icon(
                                          item.parentId != null
                                              ? Icons.more_outlined
                                              : Icons.more_horiz,
                                          color: overlayTextColor,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  right: 7,
                                  bottom: 7,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: overlayColor,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        '${Resolution.match(item.width * item.height).title} ${item.width} x ${item.height}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ).copyWith(color: overlayTextColor),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                sourceList: state.source,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontal ? 10 : 6,
                  vertical: 8,
                ),
                indicatorBuilder:
                    (context, status) => LoadingMoreIndicator(
                      status: status,
                      isSliver: true,
                      errorRefresh: () {
                        state.source.errorRefresh();
                      },
                    ),
              ),
            ),
          ],
        );
      },
      floatingActionButton:
          isDesktop
              ? FloatingActionButton(
                heroTag: '${runtimeType}FloatingActionButton',
                onPressed: () {
                  state.source.refresh(true);
                },
                child: const Icon(Icons.refresh, color: Colors.white),
              )
              : null,
    );
  }
}
