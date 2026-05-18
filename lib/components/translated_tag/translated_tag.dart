import 'package:flutter/material.dart';
import 'package:yande_gui/services/tag_translations_service.dart';
import 'package:yande_gui/ui/app_ui.dart';

class TranslatedTag extends StatelessWidget {
  final String text;

  const TranslatedTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPill(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: text,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (TagTranslationsService.translate(text)
                case final transltedText?)
              TextSpan(
                text: ' #$transltedText',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
