import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/about/about_page.dart';
import 'package:yande_gui/pages/downloads/downloads_page.dart';
import 'package:yande_gui/pages/post_list/logic.dart';
import 'package:yande_gui/pages/post_list/post_list_page.dart';
import 'package:yande_gui/pages/post_search/post_search_page.dart';
import 'package:yande_gui/pages/settings/settings_page.dart';
import 'package:yande_gui/services/booru_site_service.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:yande_gui/services/updater_service.dart';
import 'package:yande_gui/widgets/lazy_indexed_stack/lazy_indexed_stack.dart';

class IndexPage extends StatefulWidget {
  final int? language;
  final String siteKey;

  const IndexPage({super.key, required this.language, required this.siteKey});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  Map<(IconData, String), WidgetBuilder> get _pages => {
    (Icons.list_alt_outlined, i18n.postList.short):
        (context) =>
            PostListPage(key: ValueKey((widget.language, widget.siteKey, 0))),
    (Icons.local_fire_department_outlined, i18n.postList.popular):
        (context) => PostListPage(
          key: ValueKey((widget.language, widget.siteKey, 1)),
          mode: PostListMode.popular,
        ),
    (Icons.search_outlined, i18n.postSearch.title):
        (context) =>
            PostSearchPage(key: ValueKey((widget.language, widget.siteKey))),
    (Icons.cloud_download_outlined, i18n.downloads.title):
        (context) =>
            DownloadsPage(key: ValueKey((widget.language, widget.siteKey))),
    (Icons.info_outlined, i18n.about.title):
        (context) => AboutPage(key: ValueKey(widget.language)),
    (Icons.settings, i18n.settings.title):
        (context) =>
            SettingsPage(key: ValueKey((widget.language, widget.siteKey))),
  };

  final controller = PageController();

  int _selectedIndex = 0;

  late bool _initialized =
      !SettingsService.prefetchDns ||
      BooruSite.fromKey(widget.siteKey) != BooruSite.yande;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      if (!_initialized) {
        await BooruSiteService.configureClients(fetchDns: true);
        setState(() {
          _initialized = true;
        });
      }

      UpdaterService.checkForUpdate()
          .then((result) {
            if (result != null) {
              EasyLoading.showToast(
                i18n.update.newVersionFound(result.$1),
                toastPosition: EasyLoadingToastPosition.bottom,
                duration: const Duration(seconds: 6),
              );
            }
          })
          .catchError((e) {
            EasyLoading.showToast(i18n.update.checkUpdateFailed);
          });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isVertical =
        MediaQuery.of(context).size.width < MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final site = BooruSite.fromKey(widget.siteKey);

    return Scaffold(
      body: switch (_initialized) {
        false => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...'),
            ],
          ),
        ),
        true => Row(
          children: [
            if (!isVertical)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: theme.colorScheme.outlineVariant.withAlpha(120),
                    ),
                  ),
                ),
                child: NavigationRail(
                  minWidth: 92,
                  groupAlignment: -0.75,
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 22),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: Text(
                            site.displayName.substring(0, 1).toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  destinations: [
                    for (final key in _pages.keys)
                      NavigationRailDestination(
                        icon: Icon(key.$1),
                        label: Text(key.$2),
                      ),
                  ],
                  labelType: NavigationRailLabelType.all,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
              ),
            Expanded(
              child: LazyIndexedStack(
                index: _selectedIndex,
                children: [for (final page in _pages.values) page(context)],
              ),
            ),
          ],
        ),
      },
      bottomNavigationBar: switch (isVertical) {
        true => BottomNavigationBar(
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          items: [
            for (final key in _pages.keys)
              BottomNavigationBarItem(icon: Icon(key.$1), label: key.$2),
          ],
        ),
        false => null,
      },
    );
  }

  @override
  void didUpdateWidget(covariant IndexPage oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
  }
}
