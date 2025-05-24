# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Magic Card is a Flutter package for rendering Magic: The Gathering cards with foil effects. It provides widgets to display MTG cards using the Scryfall API with caching support.

## Common Commands

### Package Management
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade
```

### Linting and Analysis
```bash
# Run static analysis
flutter analyze
```

### Building
```bash
# Build the package
flutter build
```

## Architecture

### Core Components

1. **CardView** (`lib/src/card/card.dart`): Main widget for displaying MTG cards
   - Fetches card images from Scryfall API with caching via memcached
   - Supports various image sizes, back face display, and foil effects
   - Can be interactive (pan/zoom) or static

2. **FoilMagicCard** (`lib/src/card/foil_card.dart`): Simplified API for foil cards
   - Wrapper around CardView with foil effect presets
   - Configurable foil opacity and gradients

3. **TradingCard** (`lib/src/card/trading_card.dart`): 3D interactive card widget
   - Provides tilt effects and 3D transformations
   - Responds to device orientation and user interaction

### Dependencies
- **scryfall_api**: For fetching MTG card data
- **nonsense_foil**: Provides foil shader effects
- **memcached**: Caching layer for API responses
- **mtg**: MTG-related utilities
- **fast_log**: Logging utilities

### Key Design Patterns
- Image caching is handled through memcached with 5-minute TTL
- All card fetching goes through the centralized `getImage()` function
- Foil effects are composable using nested Foil widgets
- Interactive features are opt-in via boolean flags