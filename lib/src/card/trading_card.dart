import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

class TradingCard extends StatelessWidget {
  const TradingCard({
    super.key,
    required this.card,
    this.width,
    this.height,
    this.padding = EdgeInsets.zero, // Changed default padding
    this.borderRadius = 10.0,
    this.fit = BoxFit.contain, // Added fit parameter
  });

  /// A `String` representing a url leading to an image.
  final String card;

  /// Constrain the dimensions of this `TradingCard`.
  final double? width, height;

  /// Pad this `TradingCard` so a `Foil` that wraps it may have extra room
  /// in the gradient shader to accommodate this widget's [XL] as it transforms.
  final EdgeInsets padding;

  /// The border radius of the rounded corners.
  final double borderRadius;

  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: card,
          width: width,
          height: height,
          fit: fit,
          // Use the fit parameter
          placeholder: (context, url) => const CustomCircularLoader(size: 48),
          errorWidget: (context, url, error) =>
              const CustomErrorIndicator(size: 48),
          imageBuilder: (context, imageProvider) => AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
            child: Image(
              image: imageProvider,
              width: width,
              height: height,
              fit: fit,
            ),
          ),
        ),
      ),
    );
  }
}

/// A custom circular loading indicator that doesn't use Material components
class CustomCircularLoader extends StatefulWidget {
  final double size;

  const CustomCircularLoader({
    super.key,
    required this.size,
  });

  @override
  State<CustomCircularLoader> createState() => _CustomCircularLoaderState();
}

class _CustomCircularLoaderState extends State<CustomCircularLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _LoaderPainter(
              animationValue: _controller.value,
              color: const Color(0xFF666666),
            ),
          );
        },
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _LoaderPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width / 10;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw background circle with lower opacity
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withOpacity(0.2)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke);

    // Draw animated arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + (animationValue * 2 * math.pi),
      math.pi / 2 + (animationValue * math.pi),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LoaderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// A custom error indicator that doesn't use Material components
class CustomErrorIndicator extends StatelessWidget {
  final double size;
  final Color color;

  const CustomErrorIndicator({
    super.key,
    required this.size,
    this.color = const Color(0xFFFF5555),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: CustomPaint(
          size: Size(size, size),
          painter: _ErrorIconPainter(color: color),
        ),
      ),
    );
  }
}

class _ErrorIconPainter extends CustomPainter {
  final Color color;

  _ErrorIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width / 15;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      (size.width - strokeWidth) / 2,
      paint,
    );

    // Draw X inside the circle
    final double offset = size.width * 0.28;

    // Line from top-left to bottom-right
    canvas.drawLine(
      Offset(offset, offset),
      Offset(size.width - offset, size.height - offset),
      paint,
    );

    // Line from top-right to bottom-left
    canvas.drawLine(
      Offset(size.width - offset, offset),
      Offset(offset, size.height - offset),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ErrorIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
