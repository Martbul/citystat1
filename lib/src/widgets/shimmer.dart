import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:citystat1/src/styles/styles.dart';

class Shimmer extends StatefulWidget {
  static ShimmerState? of(BuildContext context) {
    return context.findAncestorStateOfType<ShimmerState>();
  }

  const Shimmer({super.key, this.child});

  final Widget? child;

  @override
  ShimmerState createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  LinearGradient get _defaultGradient {
    final brightness = Theme.of(context).brightness;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final scaffoldOpacity = scaffoldBackgroundColor.a;
    final effectiveScaffoldBackgroundColor = scaffoldBackgroundColor.withValues(
      alpha: max(0.2, scaffoldOpacity),
    );
    switch (brightness) {
      case Brightness.light when scaffoldOpacity > 0:
        return LinearGradient(
          colors: [
            darken(effectiveScaffoldBackgroundColor, 0.05),
            darken(effectiveScaffoldBackgroundColor, 0.1),
            darken(effectiveScaffoldBackgroundColor, 0.2),
          ],
          stops: const [0.1, 0.3, 0.4],
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          tileMode: TileMode.clamp,
        );

      case _:
        return LinearGradient(
          colors: [
            lighten(effectiveScaffoldBackgroundColor, 0.05),
            lighten(effectiveScaffoldBackgroundColor, 0.1),
            lighten(effectiveScaffoldBackgroundColor, 0.2),
          ],
          stops: const [0.1, 0.3, 0.4],
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          tileMode: TileMode.clamp,
        );
    }
  }

  LinearGradient get gradient => LinearGradient(
    colors: _defaultGradient.colors,
    stops: _defaultGradient.stops,
    begin: _defaultGradient.begin,
    end: _defaultGradient.end,
    transform: _SlidingGradientTransform(slidePercent: _shimmerController.value),
  );

  Listenable get shimmerChanges => _shimmerController;

  bool get isSized => (context.findRenderObject() as RenderBox?)?.hasSize ?? false;

  // ignore: cast_nullable_to_non_nullable
  Size get size => (context.findRenderObject() as RenderBox).size;

  Offset getDescendantOffset({required RenderBox descendant, Offset offset = Offset.zero}) {
    // ignore: cast_nullable_to_non_nullable
    final shimmerBox = context.findRenderObject() as RenderBox;
    return descendant.localToGlobal(offset, ancestor: shimmerBox);
  }

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox();
  }
}

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key, required this.isLoading, required this.child});

  final bool isLoading;
  final Widget child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> {
  Listenable? _shimmerChanges;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shimmerChanges != null) {
      _shimmerChanges!.removeListener(_onShimmerChange);
    }
    _shimmerChanges = Shimmer.of(context)?.shimmerChanges;
    if (_shimmerChanges != null) {
      _shimmerChanges!.addListener(_onShimmerChange);
    }
  }

  @override
  void dispose() {
    _shimmerChanges?.removeListener(_onShimmerChange);
    super.dispose();
  }

  void _onShimmerChange() {
    if (widget.isLoading) {
      setState(() {
        // update the shimmer painting.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final scaffoldOpacity = Theme.of(context).scaffoldBackgroundColor.a;

    final shimmer = Shimmer.of(context)!;
    if (!shimmer.isSized) {
      return const SizedBox();
    }
    final shimmerSize = shimmer.size;
    final gradient = shimmer.gradient;
    final offsetWithinShimmer = shimmer.getDescendantOffset(
      // ignore: cast_nullable_to_non_nullable
      descendant: context.findRenderObject() as RenderBox,
    );

    return ShaderMask(
      blendMode: scaffoldOpacity == 0 ? BlendMode.modulate : BlendMode.srcATop,
      shaderCallback: (bounds) {
        return gradient.createShader(
          Rect.fromLTWH(
            -offsetWithinShimmer.dx,
            -offsetWithinShimmer.dy,
            shimmerSize.width,
            shimmerSize.height,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
