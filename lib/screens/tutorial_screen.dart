import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

// ── v2 design tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF43102B);
const _kSub = Color(0xFF514348);
const _kText = Color(0xFF1C1B1A);
const _kBorder = Color(0xFFD5C2C7);

class TutorialScreen extends StatefulWidget {
  final bool useNewUi;
  const TutorialScreen({super.key, this.useNewUi = false});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  Map<String, List<String>> _sectionImages = {};
  bool _imagesLoaded = false;
  late final List<ExpansibleController> _controllers;

  static const List<_TutorialSection> _sections = [
    _TutorialSection(
      key: 'navigation',
      prefix: 'navigation_',
      icon: Icons.cottage_outlined,
      titleKey: 'tutorial_section_navigation',
      descKey: 'tutorial_desc_navigation',
    ),
    _TutorialSection(
      key: 'adding_books',
      prefix: 'adding_books_',
      icon: Icons.add_circle_outline,
      titleKey: 'tutorial_section_adding_books',
      descKey: 'tutorial_desc_adding_books',
    ),
    _TutorialSection(
      key: 'book_detail',
      prefix: 'book_detail_',
      icon: Icons.menu_book_outlined,
      titleKey: 'tutorial_section_book_detail',
      descKey: 'tutorial_desc_book_detail',
    ),
    _TutorialSection(
      key: 'my_books',
      prefix: 'my_books_',
      icon: Icons.bookmark_outline,
      titleKey: 'tutorial_section_my_books',
      descKey: 'tutorial_desc_my_books',
    ),
    _TutorialSection(
      key: 'statistics',
      prefix: 'statistics_',
      icon: Icons.donut_large_outlined,
      titleKey: 'tutorial_section_statistics',
      descKey: 'tutorial_desc_statistics',
    ),
    _TutorialSection(
      key: 'book_competition',
      prefix: 'book_competition_',
      icon: Icons.emoji_events_outlined,
      titleKey: 'tutorial_section_book_competition',
      descKey: 'tutorial_desc_book_competition',
    ),
    _TutorialSection(
      key: 'random',
      prefix: 'random_',
      icon: Icons.shuffle_outlined,
      titleKey: 'tutorial_section_random',
      descKey: 'tutorial_desc_random',
    ),
    _TutorialSection(
      key: 'settings',
      prefix: 'settings_',
      icon: Icons.settings_outlined,
      titleKey: 'tutorial_section_settings',
      descKey: 'tutorial_desc_settings',
    ),
    _TutorialSection(
      key: 'library_tools',
      prefix: 'library_tools_',
      icon: Icons.build_outlined,
      titleKey: 'tutorial_section_library_tools',
      descKey: 'tutorial_desc_library_tools',
    ),
    _TutorialSection(
      key: 'dialogs',
      prefix: 'dialogs_',
      icon: Icons.chat_bubble_outline,
      titleKey: 'tutorial_section_dialogs',
      descKey: 'tutorial_desc_dialogs',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _sections.length,
      (_) => ExpansibleController(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadImages());
  }

  Future<void> _loadImages() async {
    final manifest = await AssetManifest.loadFromAssetBundle(
      DefaultAssetBundle.of(context),
    );
    final allPaths =
        manifest
            .listAssets()
            .where((k) => k.startsWith('assets/tutorial/complete/'))
            .toList()
          ..sort();

    final Map<String, List<String>> result = {};
    for (final section in _sections) {
      result[section.key] =
          allPaths
              .where((p) => p.split('/').last.startsWith(section.prefix))
              .toList();
    }

    if (mounted) {
      setState(() {
        _sectionImages = result;
        _imagesLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useNewUi) {
      return _buildV2(context);
    }
    return _buildV1(context);
  }

  Widget _buildV1(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tutorial_title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final section = _sections[index];
          final images =
              _imagesLoaded ? (_sectionImages[section.key] ?? []) : [];
          return _TutorialSectionCard(
            section: section,
            images: images,
            l10n: l10n,
            controller: _controllers[index],
            onExpansionChanged: (expanded) {
              if (expanded) {
                for (int i = 0; i < _controllers.length; i++) {
                  if (i != index) {
                    try {
                      _controllers[i].collapse();
                    } catch (_) {}
                  }
                }
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildV2(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.tutorial_title,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder.withValues(alpha: 0.5)),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
        itemCount: _sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final section = _sections[index];
          final images =
              _imagesLoaded ? (_sectionImages[section.key] ?? []) : [];
          return _TutorialSectionCardV2(
            section: section,
            images: images,
            l10n: l10n,
            controller: _controllers[index],
            onExpansionChanged: (expanded) {
              if (expanded) {
                for (int i = 0; i < _controllers.length; i++) {
                  if (i != index) {
                    try {
                      _controllers[i].collapse();
                    } catch (_) {}
                  }
                }
              }
            },
          );
        },
      ),
    );
  }
}

class _TutorialSection {
  final String key;
  final String prefix;
  final IconData icon;
  final String titleKey;
  final String descKey;

  const _TutorialSection({
    required this.key,
    required this.prefix,
    required this.icon,
    required this.titleKey,
    required this.descKey,
  });
}

class _TutorialSectionCard extends StatelessWidget {
  final _TutorialSection section;
  final List<dynamic> images;
  final AppLocalizations l10n;
  final ExpansibleController? controller;
  final ValueChanged<bool>? onExpansionChanged;

  const _TutorialSectionCard({
    required this.section,
    required this.images,
    required this.l10n,
    this.controller,
    this.onExpansionChanged,
  });

  String _getTitle(AppLocalizations l10n) {
    switch (section.key) {
      case 'navigation':
        return l10n.tutorial_section_navigation;
      case 'adding_books':
        return l10n.tutorial_section_adding_books;
      case 'book_detail':
        return l10n.tutorial_section_book_detail;
      case 'my_books':
        return l10n.tutorial_section_my_books;
      case 'statistics':
        return l10n.tutorial_section_statistics;
      case 'book_competition':
        return l10n.tutorial_section_book_competition;
      case 'random':
        return l10n.tutorial_section_random;
      case 'settings':
        return l10n.tutorial_section_settings;
      case 'library_tools':
        return l10n.tutorial_section_library_tools;
      case 'dialogs':
        return l10n.tutorial_section_dialogs;
      default:
        return section.key;
    }
  }

  String _getDescription(AppLocalizations l10n) {
    switch (section.key) {
      case 'navigation':
        return l10n.tutorial_desc_navigation;
      case 'adding_books':
        return l10n.tutorial_desc_adding_books;
      case 'book_detail':
        return l10n.tutorial_desc_book_detail;
      case 'my_books':
        return l10n.tutorial_desc_my_books;
      case 'statistics':
        return l10n.tutorial_desc_statistics;
      case 'book_competition':
        return l10n.tutorial_desc_book_competition;
      case 'random':
        return l10n.tutorial_desc_random;
      case 'settings':
        return l10n.tutorial_desc_settings;
      case 'library_tools':
        return l10n.tutorial_desc_library_tools;
      case 'dialogs':
        return l10n.tutorial_desc_dialogs;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = _getTitle(l10n);
    final description = _getDescription(l10n);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        controller: controller,
        onExpansionChanged: onExpansionChanged,
        leading: Icon(section.icon, color: colorScheme.primary),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final path = images[index] as String;
                  return GestureDetector(
                    onTap: () => _openFullScreen(context, images, index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: Image.asset(
                          path,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openFullScreen(
    BuildContext context,
    List<dynamic> images,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => _FullScreenImageViewer(
              images: images.cast<String>(),
              initialIndex: initialIndex,
            ),
      ),
    );
  }
}

class _TutorialSectionCardV2 extends _TutorialSectionCard {
  const _TutorialSectionCardV2({
    required super.section,
    required super.images,
    required super.l10n,
    super.controller,
    super.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final title = _getTitle(l10n);
    final description = _getDescription(l10n);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A27231E)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          controller: controller,
          onExpansionChanged: onExpansionChanged,
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.white,
          iconColor: _kPrimary,
          collapsedIconColor: _kSub,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(section.icon, color: _kPrimary, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kText,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  color: _kSub,
                  height: 1.4,
                ),
              ),
            ),
            if (images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final path = images[index] as String;
                    return GestureDetector(
                      onTap: () => _openFullScreen(context, images, index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 9 / 16,
                          child: Image.asset(
                            path,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  color: const Color(0xFFF2EDEB),
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: _kSub,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: false,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.asset(
                    widget.images[index],
                    fit: BoxFit.contain,
                    errorBuilder:
                        (_, __, ___) => Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 64,
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                  ),
                ),
              );
            },
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
