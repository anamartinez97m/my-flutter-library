import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/role_provider.dart';
import 'package:myrandomlibrary/screens/new_ui/new_random_books_screen.dart';
import 'package:myrandomlibrary/screens/new_ui/new_random_filters_screen.dart';
import 'package:myrandomlibrary/screens/new_ui/new_random_mood_screen.dart';
import 'package:provider/provider.dart';

const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF43102B);
const _kSub = Color(0xFF514348);

/// Random tab: one card per way of getting a recommendation (mood, specific
/// books, filters), each opening its own screen.
class NewRandomScreen extends StatefulWidget {
  const NewRandomScreen({super.key});
  @override
  State<NewRandomScreen> createState() => _NewRandomScreenState();
}

class _NewRandomScreenState extends State<NewRandomScreen> {
  final _filters = RandomFilters();
  final _bookSelection = RandomBookSelection();

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = context.watch<RoleProvider>().isAdmin;
    return Scaffold(
      backgroundColor: _kBg,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.discover_next_read,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.set_preferences_description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _kPrimary),
            ),
            const SizedBox(height: 16),
            if (isAdmin) ...[
              Expanded(
                child: _RandomOptionCard(
                  icon: Icons.auto_awesome,
                  title: l10n.theme_discovery_title,
                  subtitle: l10n.theme_discovery_subtitle,
                  onTap: () => _open(const NewRandomMoodScreen()),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: _RandomOptionCard(
                icon: Icons.library_books,
                title: l10n.select_books,
                subtitle: l10n.random_books_card_subtitle,
                onTap:
                    () =>
                        _open(NewRandomBooksScreen(selection: _bookSelection)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _RandomOptionCard(
                icon: Icons.tune,
                title: l10n.filters,
                subtitle: l10n.random_filters_card_subtitle,
                onTap: () => _open(NewRandomFiltersScreen(filters: _filters)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width card styled like the stats screen bento cards.
class _RandomOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RandomOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: radius,
            border: Border.all(color: const Color(0x1A27231E)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: _kPrimary),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kSub,
                    letterSpacing: 0.26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
