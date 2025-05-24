import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
          placeholder: (context, url) => Skeletonizer(
            enabled: true,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
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
