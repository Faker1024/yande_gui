import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yande_gui/components/translated_tag/translated_tag.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/downloader/downloader.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/post_detail/post_detail_page.dart';
import 'package:yande_gui/services/download_history_service.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:yande_gui/ui/app_ui.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

import 'download_task.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  String _formatDateTime(int millisecondsSinceEpoch) {
    final dateTime =
        DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch).toLocal();
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildHistoryTile(BuildContext context, DownloadHistoryItem item) {
    final statusColor = switch (item.status) {
      DownloadHistoryStatus.completed => Colors.green,
      DownloadHistoryStatus.failed => Theme.of(context).colorScheme.error,
    };
    final statusText = switch (item.status) {
      DownloadHistoryStatus.completed => i18n.downloads.completed,
      DownloadHistoryStatus.failed => i18n.downloads.failed,
    };
    final timeText = switch (item.status) {
      DownloadHistoryStatus.completed => i18n.downloads.savedAt(
        _formatDateTime(item.createdAt),
      ),
      DownloadHistoryStatus.failed => i18n.downloads.failedAt(
        _formatDateTime(item.createdAt),
      ),
    };

    return AppPanel(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.all(8),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostDetailPage(post: item.post),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: YandeImage(item.post.previewUrl, width: 96, height: 96),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ID:${item.post.id}  ${item.fileName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AppPill(
                        color: statusColor,
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ClipRect(
                      child: Wrap(
                        runSpacing: 6,
                        spacing: 6,
                        children: [
                          for (final tag in item.post.tags.split(' ').take(8))
                            TranslatedTag(text: tag),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: i18n.generic.clear,
            onPressed: () {
              DownloadHistoryService.remove(item);
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AutoScaffold(
      verticalOnlyTitleWidget: Text(i18n.downloads.title),
      floatingActionButton: FloatingActionButton(
        heroTag: '${runtimeType}FloatingActionButton',
        onPressed: () {
          Downloader.instance.retryAll();
        },
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      builder: (context, horizontal) {
        return StreamBuilder<void>(
          stream: SettingsService.downloadHistoryStream,
          builder: (context, _) {
            return StreamBuilder(
              stream: Downloader.instance.taskListStream,
              builder: (context, snapshot) {
                final list = snapshot.data ?? Downloader.instance.taskList;
                final currentFileNames =
                    list.map((task) => task.fileName).toSet();
                final history = DownloadHistoryService.items
                    .where((item) => !currentFileNames.contains(item.fileName))
                    .toList(growable: false);

                return ListView(
                  children: [
                    if (list.isNotEmpty)
                      AppSectionHeader(title: i18n.downloads.activeTasks),
                    for (final task in list.reversed)
                      DownloadTaskWidget(task: task),
                    if (history.isNotEmpty)
                      AppSectionHeader(
                        title: i18n.downloads.history,
                        trailing: IconButton(
                          tooltip: i18n.downloads.clearHistory,
                          onPressed: DownloadHistoryService.clear,
                          icon: const Icon(Icons.delete_sweep_outlined),
                        ),
                      ),
                    for (final item in history)
                      _buildHistoryTile(context, item),
                    if (list.isEmpty && history.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.25,
                        ),
                        child: Center(child: Text(i18n.downloads.noHistory)),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
