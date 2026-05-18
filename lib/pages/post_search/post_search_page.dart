import 'package:flutter/material.dart';
import 'package:yande_gui/components/translated_tag/translated_tag.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/post_list/post_list_page.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:yande_gui/services/tag_translations_service.dart';
import 'package:yande_gui/ui/app_ui.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

class PostSearchPage extends StatefulWidget {
  const PostSearchPage({super.key});

  @override
  State<PostSearchPage> createState() => _PostSearchPageState();
}

class _PostSearchPageState extends State<PostSearchPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _textScrollController = ScrollController();
  bool _hasTextContent = false;

  static final _tags = TagTranslationsService.knowTags;

  String _normalizeSearchText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _openSearch(String text) {
    final normalized = _normalizeSearchText(text);
    if (normalized.isEmpty) return;

    SettingsService.addSearchHistory(normalized);
    setState(() {
      _hasTextContent = true;
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostListPage(tags: normalized.split(' ')),
      ),
    );
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            scrollController: _textScrollController,
            onChanged: (text) {
              if (text.isEmpty == _hasTextContent) {
                setState(() {
                  _hasTextContent = text.isNotEmpty;
                });
              }
            },
            onSubmitted: (value) {
              _openSearch(value);
            },
            decoration: InputDecoration(
              filled: true,
              hintText: i18n.postSearch.title,
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).inputDecorationTheme.hintStyle?.color,
              ),
              suffixIcon:
                  _hasTextContent
                      ? IconButton(
                        icon: Icon(
                          Icons.cancel,
                          color:
                              Theme.of(
                                context,
                              ).inputDecorationTheme.hintStyle?.color,
                        ),
                        onPressed: () {
                          _textController.clear();
                          setState(() {
                            _hasTextContent = false;
                          });
                        },
                      )
                      : null,
            ),
          ),
        ),
        if (_hasTextContent)
          IconButton(
            onPressed: () {
              _openSearch(_textController.text);
            },
            icon: const Icon(Icons.search),
          ),
      ],
    );
  }

  Widget _buildSearchHistory() {
    final history = SettingsService.searchHistory;
    if (history.isEmpty) return const SizedBox.shrink();

    return AppPanel(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  i18n.postSearch.history,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: i18n.postSearch.clearHistory,
                onPressed: () {
                  SettingsService.clearSearchHistory();
                  setState(() {});
                },
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ],
          ),
          Wrap(
            runSpacing: 6,
            spacing: 6,
            children: [
              for (final item in history)
                InputChip(
                  label: Text(item),
                  onPressed: () {
                    _textController.text = item;
                    _textController.selection = TextSelection.fromPosition(
                      TextPosition(offset: item.length),
                    );
                    _openSearch(item);
                  },
                  onDeleted: () {
                    SettingsService.removeSearchHistory(item);
                    setState(() {});
                  },
                  deleteIcon: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      verticalOnlyTitleWidget: Text(i18n.postSearch.title),
      builder: (context, horizontal) {
        return Column(
          children: [
            AppPanel(
              margin: EdgeInsets.fromLTRB(
                horizontal ? 20 : 12,
                14,
                horizontal ? 20 : 12,
                10,
              ),
              padding: const EdgeInsets.all(10),
              child: _buildSearchField(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal ? 20 : 12,
                    0,
                    horizontal ? 20 : 12,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchHistory(),
                      AppSectionHeader(
                        title: i18n.postSearch.title,
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
                      ),
                      Wrap(
                        runSpacing: 6,
                        spacing: 6,
                        children: [
                          for (final tag in _tags)
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                final text = _textController.text;
                                if (!text.split(' ').contains(tag)) {
                                  _textController.text = '${text.trim()} $tag';
                                  if (!_hasTextContent) {
                                    setState(() {
                                      _hasTextContent = true;
                                    });
                                  }
                                  _textController
                                      .selection = TextSelection.fromPosition(
                                    TextPosition(
                                      offset: _textController.text.length,
                                    ),
                                  );
                                  Future.delayed(
                                    const Duration(milliseconds: 100),
                                    () {
                                      if (_textScrollController.hasClients) {
                                        _textScrollController.jumpTo(
                                          _textScrollController
                                              .position
                                              .maxScrollExtent,
                                        );
                                      }
                                    },
                                  );
                                }
                              },
                              child: TranslatedTag(text: tag),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _textScrollController.dispose();
    super.dispose();
  }
}
