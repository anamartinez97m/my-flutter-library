import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/discovery/index/searchable_text_builder.dart';
import 'package:myrandomlibrary/discovery/model/discovery_result.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/widgets/book_card_v2.dart';

const _kPrimary = V2Colors.primary;
const _kSub = V2Colors.textSecondary;
final _kChipBg = V2Colors.chip.withValues(alpha: 0.5);
final _kChipBorder = V2Colors.border.withValues(alpha: 0.5);
const _kTrack = V2Colors.divider;

/// A [BookCardV2] plus how well the book matches the discovery query:
/// relevance (percentage and bar), matched concepts and a short "why".
class DiscoveryResultCard extends StatelessWidget {
  static const int _maxChips = 4;
  static const int _maxReasons = 2;

  final DiscoveryResult result;

  const DiscoveryResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final why = _whyLine(l10n);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookCardV2(
            book: result.book,
            enabledCardFields: const {
              'title',
              'author',
              'saga',
              'saga_universe',
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.theme_discovery_match_percent(
                        result.relevancePercent,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: result.relevance,
                          minHeight: 4,
                          backgroundColor: _kTrack,
                          valueColor: const AlwaysStoppedAnimation(_kPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
                if (result.matchedConcepts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final match in result.matchedConcepts.take(
                        _maxChips,
                      ))
                        _ConceptChip(
                          label:
                              '${match.concept.emoji} '
                              '${match.concept.localizedName(languageCode)}',
                          isDirect: match.isDirect,
                        ),
                    ],
                  ),
                ],
                if (why.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    why,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _kSub),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _whyLine(AppLocalizations l10n) {
    final seen = <String>{};
    final parts = <String>[];
    for (final reason in result.reasons) {
      if (!seen.add('${reason.term}|${reason.field.name}')) continue;
      parts.add(
        l10n.theme_discovery_reason_in_field(
          reason.term,
          _fieldLabel(reason.field, l10n),
        ),
      );
      if (parts.length == _maxReasons) break;
    }
    return parts.join(' · ');
  }

  static String _fieldLabel(DiscoveryField field, AppLocalizations l10n) =>
      switch (field) {
        DiscoveryField.title => l10n.discovery_field_title,
        DiscoveryField.genre => l10n.discovery_field_genre,
        DiscoveryField.saga => l10n.discovery_field_saga,
        DiscoveryField.description => l10n.discovery_field_description,
        DiscoveryField.author => l10n.discovery_field_author,
        DiscoveryField.notes => l10n.discovery_field_notes,
      };
}

class _ConceptChip extends StatelessWidget {
  final String label;
  final bool isDirect;

  const _ConceptChip({required this.label, required this.isDirect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDirect ? _kPrimary.withValues(alpha: 0.08) : _kChipBg,
        border: Border.all(
          color: isDirect ? _kPrimary.withValues(alpha: 0.35) : _kChipBorder,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: _kPrimary,
          fontWeight: isDirect ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
