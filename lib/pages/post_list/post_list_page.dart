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
import 'package:yande_gui/services/booru_site_service.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

import 'logic.dart';

class PostListPage extends ConsumerStatefulWidget {
  final List<String>? tags;
  final PostListMode mode;

  const PostListPage({super.key, this.tags, this.mode = PostListMode.recent});

  @override
  ConsumerState createState() => _PostListPageState();
}

const double _kActivityIndicatorRadius = 14.0;

class _PostListPageState extends ConsumerState<PostListPage> {
  late final List<String> _providerTags = widget.tags ?? const <String>[];

  PopularScale _popularScale = PopularScale.day;
  late DateTime _popularDate = _dateOnly(DateTime.now());

  PostListProvider get provider => postListProvider(
    runtimeType,
    siteKey: SettingsService.siteKey,
    tags: _providerTags,
    mode: widget.mode,
    popularScale: _popularScale,
    popularDate: _popularDate,
  );

  bool get needTopPadding =>
      widget.tags == null && widget.mode == PostListMode.recent;

  bool get _isPopular => widget.mode == PostListMode.popular;

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static DateTime _addMonths(DateTime date, int months) {
    final target = DateTime(date.year, date.month + months);
    final day =
        date.day.clamp(1, _daysInMonth(target.year, target.month)).toInt();
    return DateTime(target.year, target.month, day);
  }

  DateTime _shiftPopularDate(int direction) {
    return switch (_popularScale) {
      PopularScale.day => _popularDate.add(Duration(days: direction)),
      PopularScale.week => _popularDate.add(Duration(days: 7 * direction)),
      PopularScale.month => _addMonths(_popularDate, direction),
      PopularScale.year => DateTime(
        _popularDate.year + direction,
        _popularDate.month,
        _popularDate.day
            .clamp(
              1,
              _daysInMonth(_popularDate.year + direction, _popularDate.month),
            )
            .toInt(),
      ),
    };
  }

  bool get _canShowNextPeriod {
    final next = _dateOnly(_shiftPopularDate(1));
    return !next.isAfter(_dateOnly(DateTime.now()));
  }

  void _setPopularDate(DateTime date) {
    final today = _dateOnly(DateTime.now());
    final normalized = _dateOnly(date);
    setState(() {
      _popularDate = normalized.isAfter(today) ? today : normalized;
    });
  }

  Future<void> _pickPopularDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _popularDate,
      firstDate: DateTime(2005),
      lastDate: _dateOnly(DateTime.now()),
    );
    if (picked != null) {
      _setPopularDate(picked);
    }
  }

  String _popularDateText() {
    return switch (_popularScale) {
      PopularScale.day || PopularScale.week => _formatDate(_popularDate),
      PopularScale.month =>
        '${_popularDate.year.toString().padLeft(4, '0')}-${_popularDate.month.toString().padLeft(2, '0')}',
      PopularScale.year => _popularDate.year.toString().padLeft(4, '0'),
    };
  }

  String _formatDate(DateTime date) {
    return [
      date.year.toString().padLeft(4, '0'),
      date.month.toString().padLeft(2, '0'),
      date.day.toString().padLeft(2, '0'),
    ].join('-');
  }

  String _scaleLabel(PopularScale scale) {
    return switch (scale) {
      PopularScale.day => i18n.postList.popularDay,
      PopularScale.week => i18n.postList.popularWeek,
      PopularScale.month => i18n.postList.popularMonth,
      PopularScale.year => i18n.postList.popularYear,
    };
  }

  Widget _buildPopularControls(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        spacing: 8,
        children: [
          SegmentedButton<PopularScale>(
            showSelectedIcon: false,
            segments: [
              for (final scale in PopularScale.values)
                ButtonSegment(value: scale, label: Text(_scaleLabel(scale))),
            ],
            selected: {_popularScale},
            onSelectionChanged: (selection) {
              setState(() {
                _popularScale = selection.first;
              });
            },
          ),
          IconButton.outlined(
            tooltip: i18n.postList.previousPopularPeriod,
            onPressed: () {
              _setPopularDate(_shiftPopularDate(-1));
            },
            icon: const Icon(Icons.chevron_left),
          ),
          OutlinedButton.icon(
            onPressed: _pickPopularDate,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(_popularDateText(), style: theme.textTheme.labelLarge),
          ),
          IconButton.outlined(
            tooltip: i18n.postList.nextPopularPeriod,
            onPressed:
                _canShowNextPeriod
                    ? () {
                      _setPopularDate(_shiftPopularDate(1));
                    }
                    : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

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
            if (widget.tags != null || _isPopular)
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
                  _ when _isPopular => Text(i18n.postList.popular),
                  _ => Text(i18n.postList.title),
                },
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(_isPopular ? 112 : 1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isPopular) _buildPopularControls(context),
                      Divider(
                        color: theme.colorScheme.outlineVariant.withAlpha(120),
                        height: 1,
                      ),
                    ],
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
                heroTag:
                    '${runtimeType}_${widget.mode}_${widget.tags?.join('_') ?? 'root'}FloatingActionButton',
                onPressed: () {
                  state.source.refresh(true);
                },
                child: const Icon(Icons.refresh, color: Colors.white),
              )
              : null,
    );
  }
}
