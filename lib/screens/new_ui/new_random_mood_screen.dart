import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/utils/saga_order_filter.dart';
import 'package:myrandomlibrary/widgets/random_pick_scaffold.dart';
import 'package:myrandomlibrary/widgets/theme_discovery_card.dart';

const _kBg = V2Colors.background;

/// Theme / mood search over the library, opened from the random tab.
class NewRandomMoodScreen extends StatelessWidget {
  const NewRandomMoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return withManrope(
      context,
      Scaffold(
        backgroundColor: _kBg,
        appBar: randomAppBar(context, l10n.random_mood),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: ThemeDiscoveryCard(
            bookFilter: (books) => filterBySagaOrder(books, books),
          ),
        ),
      ),
    );
  }
}
