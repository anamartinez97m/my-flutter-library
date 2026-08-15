import 'package:flutter/material.dart';

const _kDefaultLoadingBackground = Color(0xFFFDF8F6);
const _kDefaultShimmerBase = Color(0xFFF2E8E3);
const _kDefaultShimmerHighlight = Color(0xFFFFFFFF);

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    this.child,
    this.backgroundColor = _kDefaultLoadingBackground,
    this.baseColor = _kDefaultShimmerBase,
    this.highlightColor = _kDefaultShimmerHighlight,
  });

  final Widget? child;
  final Color backgroundColor;
  final Color baseColor;
  final Color highlightColor;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(
        min: -0.5,
        max: 1.5,
        period: const Duration(milliseconds: 1200),
      );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  LinearGradient get _shimmerGradient => LinearGradient(
    colors: [widget.baseColor, widget.highlightColor, widget.baseColor],
    stops: const [0.1, 0.3, 0.4],
    begin: const Alignment(-1.0, -0.3),
    end: const Alignment(1.0, 0.3),
    tileMode: TileMode.clamp,
    transform: _SlidingGradientTransform(_shimmerController.value),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Center(
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) => _shimmerGradient.createShader(bounds),
              blendMode: BlendMode.srcATop,
              child: child,
            );
          },
          child: widget.child ?? _defaultPlaceholder,
        ),
      ),
    );
  }

  Widget get _defaultPlaceholder => const Padding(
    padding: EdgeInsets.all(24.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlaceholderBox(width: 280, height: 120, borderRadius: 16),
        SizedBox(height: 16),
        _PlaceholderBox(width: 200, height: 16, borderRadius: 8),
        SizedBox(height: 12),
        _PlaceholderBox(width: 140, height: 16, borderRadius: 8),
      ],
    ),
  );
}

class _PlaceholderBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _PlaceholderBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0, 0);
  }
}
