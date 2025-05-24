import 'package:cached_network_image/cached_network_image.dart';
import 'package:fast_log/fast_log.dart';
import 'package:flutter/widgets.dart';
import 'package:magic_card/magic_card.dart';
import 'package:memcached/memcached.dart';
import 'package:scryfall_api/scryfall_api.dart';
import 'package:skeletonizer/skeletonizer.dart';

ScryfallApiClient? _sf;

ScryfallApiClient sfClient() {
  if (_sf == null) {
    _sf = ScryfallApiClient();
    verbose("Initialized Scryfall API client");
  }
  return _sf!;
}

/// Retry a future operation with exponential backoff
Future<T> retryWithBackoff<T>({
  required Future<T> Function() operation,
  int maxAttempts = 5,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  int attempt = 0;
  Duration delay = initialDelay;

  while (attempt < maxAttempts) {
    try {
      verbose("Attempting operation, attempt ${attempt + 1}/$maxAttempts");
      return await operation();
    } catch (e) {
      attempt++;
      if (attempt >= maxAttempts) {
        error("All retry attempts failed: $e");
        rethrow;
      }
      error("Attempt $attempt failed: $e. Retrying in ${delay.inSeconds}s...");
      await Future.delayed(delay);
      delay *= 2; // Exponential backoff
    }
  }

  throw Exception("Failed after $maxAttempts attempts");
}

/// Cache card data with retry logic
Future<MtgCard> getCachedCardData(String cardId) async {
  String cacheKey = "cardData_$cardId";
  verbose("Fetching card data with cache key: $cacheKey");

  return getCached(
    id: cacheKey,
    getter: () => retryWithBackoff(
      operation: () => sfClient().getCardById(cardId),
      maxAttempts: 10, // Keep retrying until we get the data
      initialDelay: const Duration(seconds: 1),
    ),
    duration: const Duration(days: 7), // Cache card data for a week
  );
}

Future<String> getImageUrl({
  required String id,
  ImageVersion size = ImageVersion.normal,
  bool back = false,
}) async {
  String cacheKey = "cardUrl$id$back${size.index}";
  verbose("Fetching image URL with cache key: $cacheKey");

  return getCached(
    id: cacheKey,
    getter: () async {
      // Use cached card data with retry logic
      final card = await getCachedCardData(id);

      // Handle double-faced cards
      if (back && card.cardFaces != null && card.cardFaces!.length > 1) {
        final backFace = card.cardFaces![1];
        if (backFace.imageUris != null) {
          return _getImageUrlForSize(backFace.imageUris!, size);
        }
      }

      // Handle single-faced cards or front face
      if (card.imageUris != null) {
        return _getImageUrlForSize(card.imageUris!, size);
      } else if (card.cardFaces != null && card.cardFaces!.isNotEmpty) {
        final frontFace = card.cardFaces![0];
        if (frontFace.imageUris != null) {
          return _getImageUrlForSize(frontFace.imageUris!, size);
        }
      }

      throw Exception("No image URL found for card $id");
    },
    duration: const Duration(days: 30), // Cache URLs for a month
  );
}

String _getImageUrlForSize(ImageUris uris, ImageVersion size) {
  switch (size) {
    case ImageVersion.small:
      return uris.small.toString();
    case ImageVersion.normal:
      return uris.normal.toString();
    case ImageVersion.large:
      return uris.large.toString();
    case ImageVersion.png:
      return uris.png.toString();
    case ImageVersion.artCrop:
      return uris.artCrop.toString();
    case ImageVersion.borderCrop:
      return uris.borderCrop.toString();
  }
}

class CardView extends StatelessWidget {
  final String id;
  final ImageVersion size;
  final bool back;
  final bool foil;
  final bool flat;
  final bool interactive;
  final bool interactive3D;
  final double borderRadius;

  const CardView({
    super.key,
    required this.id,
    this.interactive3D = true,
    this.interactive = false,
    this.size = ImageVersion.normal,
    this.back = false,
    this.foil = false,
    this.flat = true,
    this.borderRadius = 16.0,
  }) : assert((interactive && !flat) || !interactive,
            "Interactive cards must be non-flat");

  Widget buildImage(BuildContext context, String imageUrl) {
    verbose("Building image widget with URL: $imageUrl");
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => Skeletonizer(
            enabled: true,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Center(
              child: Text(
                'Failed to load image',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
          ),
          imageBuilder: (context, imageProvider) => AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCirc,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget interactiveWrap(BuildContext context, Widget child) {
    info("Wrapping image for interactive viewing");
    return interactive ? InteractiveViewer(minScale: 0.1, child: child) : child;
  }

  Widget wrap(BuildContext context, Widget child) {
    verbose("Applying foil effects");
    return Foil(
      isUnwrapped: !foil,
      opacity: 0.4,
      scalar: const Scalar(horizontal: 0.2, vertical: 0.2),
      child: Foil(
        isUnwrapped: !foil,
        opacity: 0.2,
        scalar: const Scalar(horizontal: 0.55, vertical: 0.55),
        gradient: Foils.linearLoopingReversed,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    info("Building main card view widget");
    return FutureBuilder<String>(
      future: getImageUrl(id: id, size: size, back: back),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Skeletonizer(
            enabled: true,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8 * 1.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          error("Error loading image URL: ${snapshot.error}");
          // This should never happen now with retry logic, but if it does,
          // the error will be logged and cached data will be retried
          return Skeletonizer(
            enabled: true,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8 * 1.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          );
        }

        final imageUrl = snapshot.data;
        if (imageUrl == null || imageUrl.isEmpty) {
          // This should also never happen with our new logic
          return Skeletonizer(
            enabled: true,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8 * 1.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          );
        }

        success("Image URL fetched successfully: $imageUrl");
        return interactiveWrap(
          context,
          !flat
              ? wrap(context, buildImage(context, imageUrl))
              : buildImage(context, imageUrl),
        );
      },
    );
  }
}

/// A simplified function to get a Magic card widget with optional foil effect
Widget getMagicCard({
  required String scryfallId,
  bool isFoil = false,
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
  double primaryFoilOpacity = 0.4,
  double secondaryFoilOpacity = 0.25,
  Gradient primaryFoilGradient = Foils.linearRainbow,
  Gradient secondaryFoilGradient = Foils.oilslick,
  double borderRadius = 16.0,
}) {
  return FoilMagicCard(
    scryfallId: scryfallId,
    isFoil: isFoil,
    width: width,
    height: height,
    fit: fit,
    primaryFoilOpacity: primaryFoilOpacity,
    secondaryFoilOpacity: secondaryFoilOpacity,
    primaryFoilGradient: primaryFoilGradient,
    secondaryFoilGradient: secondaryFoilGradient,
    borderRadius: borderRadius,
  );
}
