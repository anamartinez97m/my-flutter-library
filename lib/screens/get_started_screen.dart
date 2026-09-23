import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/screens/new_ui/new_navigation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrimary = Color(0xFF43102B);
const _kBackground = Color(0xFFFDF8F6);
const _kSurface = Color(0xFFFFFCFA);
const _kBorder = Color(0xFFD5C2C7);
const _kMuted = Color(0xFF76656B);
const _kText = Color(0xFF1C1B1A);

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<String> _imagePaths = [];
  bool _isLoading = true;
  bool _loadFailed = false;

  static const String _onboardingKey = 'has_seen_onboarding';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadImages());
  }

  Future<void> _loadImages() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(
        DefaultAssetBundle.of(context),
      );
      final allKeys =
          manifest
              .listAssets()
              .where((k) => k.startsWith('assets/tutorial/get_started/'))
              .toList()
            ..sort();

      if (mounted) {
        setState(() {
          _imagePaths = allKeys;
          _isLoading = false;
          _loadFailed = allKeys.isEmpty;
        });
      }
    } catch (e) {
      debugPrint('📚 [GetStarted] Error loading manifest: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NewNavigationScreen()),
      );
    }
  }

  Future<void> _goToNextPage() async {
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLastPage =
        _imagePaths.isNotEmpty && _currentPage == _imagePaths.length - 1;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Manrope'),
      ),
      child: Scaffold(
        backgroundColor: _kBackground,
        body: SafeArea(
          child:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  )
                  : _loadFailed || _imagePaths.isEmpty
                  ? _buildFallback(l10n)
                  : LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalPadding =
                          constraints.maxWidth >= 600 ? 48.0 : 20.0;
                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              20,
                              horizontalPadding,
                              18,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _kPrimary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.auto_stories_rounded,
                                    color: Colors.white,
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.app_title,
                                    style: const TextStyle(
                                      color: _kPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_currentPage + 1}/${_imagePaths.length}',
                                  style: const TextStyle(
                                    color: _kMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: _imagePaths.length,
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
                              },
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding,
                                  ),
                                  child: Center(
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 520,
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _kSurface,
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(color: _kBorder),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x14000000),
                                            blurRadius: 24,
                                            offset: Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.asset(
                                          _imagePaths[index],
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (_, __, ___) => const Center(
                                                child: Icon(
                                                  Icons
                                                      .image_not_supported_outlined,
                                                  size: 56,
                                                  color: _kMuted,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              22,
                              horizontalPadding,
                              24,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_imagePaths.length, (
                                    index,
                                  ) {
                                    final isActive = index == _currentPage;
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width: isActive ? 28 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isActive ? _kPrimary : _kBorder,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 22),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 520,
                                  ),
                                  child: FilledButton.icon(
                                    onPressed:
                                        isLastPage
                                            ? _completeOnboarding
                                            : _goToNextPage,
                                    icon: Icon(
                                      isLastPage
                                          ? Icons.check_rounded
                                          : Icons.arrow_forward_rounded,
                                      size: 20,
                                    ),
                                    label: Text(
                                      isLastPage ? l10n.get_started : l10n.next,
                                    ),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(
                                        double.infinity,
                                        54,
                                      ),
                                      backgroundColor: _kPrimary,
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
        ),
      ),
    );
  }

  Widget _buildFallback(AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  l10n.app_title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _completeOnboarding,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(l10n.get_started),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
