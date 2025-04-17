import 'package:magic_card/src/card/trading_card.dart';
import 'package:mtg/util/scryfall_util.dart';
import 'package:nonsense_foil/nonsense_foil.dart';
import 'package:scryfall_api/scryfall_api.dart';

/// Returns a Widget displaying a Magic: The Gathering card with optional foil effect.
///
/// The [scryfallId] parameter is the unique identifier for the card in Scryfall's database.
/// The [isFoil] parameter determines whether to apply a foil effect to the card.
///
/// Example:
/// ```dart
/// FoilMagicCard(
///   scryfallId: '9ea1c6a8-4a1d-4d25-9f88-1b856b5e9c74',
///   isFoil: true,
/// )
/// ```
class FoilMagicCard extends StatelessWidget {
  /// The Scryfall ID of the Magic card to display
  final String scryfallId;

  /// Whether to display the card with a foil effect
  final bool isFoil;

  /// Optional width for the card
  final double? width;

  /// Optional height for the card
  final double? height;

  /// How the image should fit within its container
  final BoxFit fit;

  /// Primary foil opacity (outer layer)
  final double primaryFoilOpacity;

  /// Secondary foil opacity (inner layer)
  final double secondaryFoilOpacity;

  /// Primary foil gradient type
  final Gradient primaryFoilGradient;

  /// Secondary foil gradient type
  final Gradient secondaryFoilGradient;

  /// Creates a Magic card widget with optional foil effect
  const FoilMagicCard({
    super.key,
    required this.scryfallId,
    this.isFoil = false,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.primaryFoilOpacity = 0.4,
    this.secondaryFoilOpacity = 0.25,
    this.primaryFoilGradient = Foils.linearRainbow,
    this.secondaryFoilGradient = Foils.oilslick,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MtgCard>(
      future: ScryUtil.getCardDetails(scryfallId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(child: CustomCircularLoader(size: 48)),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            width: width,
            height: height,
            child: Center(child: Text('Error loading card: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(child: Text('Card not found')),
          );
        }

        final MtgCard card = snapshot.data!;

        // Properly handle the ImageUris object
        String? imageUrl;

        // First try to get image from card's imageUris
        if (card.imageUris != null) {
          imageUrl = card.imageUris!.normal.toString();
        }
        // If no direct imageUris, check the first card face
        else if (card.cardFaces != null && card.cardFaces!.isNotEmpty) {
          final CardFace firstFace = card.cardFaces![0];
          if (firstFace.imageUris != null) {
            imageUrl = firstFace.imageUris!.normal.toString();
          }
        }

        if (imageUrl == null || imageUrl.isEmpty) {
          return SizedBox(
            width: width,
            height: height,
            child:
                const Center(child: Text('No image available for this card')),
          );
        }

        // Create the trading card widget
        final Widget cardWidget = TradingCard(
          card: imageUrl,
          width: width,
          height: height,
          fit: fit,
          padding: EdgeInsets.zero,
          // No padding by default
          borderRadius: 16.0,
        );

        // Apply foil effect if requested
        if (isFoil) {
          return Foil(
            isUnwrapped: false,
            opacity: primaryFoilOpacity,
            gradient: primaryFoilGradient,
            scalar: const Scalar(horizontal: 0.3, vertical: 0.3),
            child: Foil(
              isUnwrapped: false,
              opacity: secondaryFoilOpacity,
              gradient: secondaryFoilGradient,
              scalar: const Scalar(horizontal: 0.5, vertical: 0.5),
              child: cardWidget,
            ),
          );
        }

        return cardWidget;
      },
    );
  }
}
