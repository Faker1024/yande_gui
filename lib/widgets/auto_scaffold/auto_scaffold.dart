import 'package:flutter/material.dart';

class AutoScaffold extends StatelessWidget {
  final Widget? verticalOnlyTitleWidget;

  final Widget? horizontalOnlyTitleWidget;

  final Widget? titleWidget;

  final Widget Function(BuildContext context, bool horizontal)? builder;

  final Widget? floatingActionButton;

  final bool? topSafeArea;

  const AutoScaffold({
    super.key,
    this.verticalOnlyTitleWidget,
    this.horizontalOnlyTitleWidget,
    this.titleWidget,
    this.builder,
    this.floatingActionButton,
    this.topSafeArea,
  });

  @override
  Widget build(BuildContext context) {
    final isVertical =
        MediaQuery.of(context).size.width < MediaQuery.of(context).size.height;

    final Widget child =
        builder?.call(context, !isVertical) ?? const SizedBox();

    final Widget? title =
        titleWidget ??
        (isVertical ? verticalOnlyTitleWidget : horizontalOnlyTitleWidget);
    final theme = Theme.of(context);

    return Scaffold(
      appBar:
          title != null
              ? AppBar(
                title: DefaultTextStyle.merge(
                  style: theme.textTheme.titleLarge,
                  child: title,
                ),
                scrolledUnderElevation: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(
                    color: theme.colorScheme.outlineVariant.withAlpha(120),
                    height: 1,
                  ),
                ),
              )
              : null,
      resizeToAvoidBottomInset: true,
      body: SafeArea(top: topSafeArea ?? true, child: child),
      floatingActionButton: floatingActionButton,
    );
  }
}
