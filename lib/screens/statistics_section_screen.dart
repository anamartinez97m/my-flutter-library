import 'package:flutter/material.dart';

/// A generic carousel screen that displays a list of stat cards
/// as swipeable pages with a dot indicator.
class StatisticsSectionScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const StatisticsSectionScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  State<StatisticsSectionScreen> createState() =>
      _StatisticsSectionScreenState();
}

class _StatisticsSectionScreenState extends State<StatisticsSectionScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(widget.title, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Page indicator
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentPage + 1} / ${widget.children.length}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Dot indicators
          if (widget.children.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.children.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          // Carousel
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.children.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      widget.children[index],
                      const SizedBox(height: 50),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
