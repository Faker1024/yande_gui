import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yande_gui/components/translated_tag/translated_tag.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/downloader/download_task.dart';
import 'package:yande_gui/downloader/downloader.dart';
import 'package:yande_gui/pages/post_detail/post_detail_page.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';
import 'package:yande_gui/ui/app_ui.dart';

class DownloadTaskWidget extends ConsumerWidget {
  final DownloadTask<Post> task;

  const DownloadTaskWidget({super.key, required this.task});

  Widget _buildStatusAction(BuildContext context, DownloadTaskState state) {
    return switch (state.status) {
      DownloadStatus.idle => IconButton(
        tooltip: 'Start',
        onPressed: () {
          Downloader.instance.startTask(task.taskId);
        },
        icon: const Icon(Icons.download_outlined),
      ),
      DownloadStatus.waiting => const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.pause_outlined),
      ),
      DownloadStatus.busying => const Padding(
        padding: EdgeInsets.all(12),
        child: CupertinoActivityIndicator(),
      ),
      DownloadStatus.completed => IconButton(
        tooltip: 'Completed',
        onPressed: () {
          Downloader.instance.startTask(task.taskId);
        },
        icon: const Icon(Icons.check_outlined),
      ),
      DownloadStatus.failed => IconButton(
        tooltip: 'Retry',
        onPressed: () {
          Downloader.instance.startTask(task.taskId);
        },
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder(
      stream: task.stream,
      builder: (
        BuildContext context,
        AsyncSnapshot<DownloadTaskState> snapshot,
      ) {
        final state = snapshot.data ?? task.state;
        final theme = Theme.of(context);

        return AppPanel(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          padding: const EdgeInsets.all(8),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PostDetailPage(post: task.inner),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: YandeImage(task.inner.previewUrl, width: 96, height: 96),
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
                              'ID:${task.inner.id}',
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(task.inner.fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(width: 4),
                          _buildStatusAction(context, state),
                        ],
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: state.progress,
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ClipRect(
                          child: Wrap(
                            runSpacing: 6,
                            spacing: 6,
                            children: [
                              for (final tag in task.inner.tags
                                  .split(' ')
                                  .take(8))
                                TranslatedTag(text: tag),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
