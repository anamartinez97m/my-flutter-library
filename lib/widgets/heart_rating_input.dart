import 'package:flutter/material.dart';

class HeartRatingInput extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;

  const HeartRatingInput({
    super.key,
    required this.initialRating,
    required this.onRatingChanged,
  });

  @override
  State<HeartRatingInput> createState() => _HeartRatingInputState();
}

class _HeartRatingInputState extends State<HeartRatingInput> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Rating',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...List.generate(5, (index) {
              final heartValue = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    // Toggle between full, half, and empty
                    if (_currentRating == heartValue) {
                      _currentRating = heartValue - 0.5;
                    } else if (_currentRating == heartValue - 0.5) {
                      _currentRating = heartValue - 1;
                    } else {
                      _currentRating = heartValue.toDouble();
                    }
                    widget.onRatingChanged(_currentRating);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildHeart(heartValue),
                ),
              );
            }),
            const SizedBox(width: 12),
            Text(
              _currentRating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tap hearts to rate (tap again for half)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }

  Widget _buildHeart(int heartValue) {
    final isFilled = _currentRating >= heartValue;
    final isHalf = !isFilled && 
                   _currentRating > heartValue - 1 && 
                   _currentRating < heartValue;

    if (isFilled) {
      return const Icon(
        Icons.favorite,
        color: Colors.red,
        size: 36,
      );
    } else if (isHalf) {
      return Stack(
        children: [
          Icon(
            Icons.favorite_border,
            color: Colors.grey[400],
            size: 36,
          ),
          ClipRect(
            clipper: HalfClipper(),
            child: const Icon(
              Icons.favorite,
              color: Colors.red,
              size: 36,
            ),
          ),
        ],
      );
    } else {
      return Icon(
        Icons.favorite_border,
        color: Colors.grey[400],
        size: 36,
      );
    }
  }
}

class HalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
