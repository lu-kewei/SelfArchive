import 'package:flutter/material.dart';

class ThemePack {
  // Backgrounds
  static const String feltBackground = 'assets/images/bg_felt.png';
  static const String freshBackground = 'assets/images/bg_fresh.png';
  static const String artisticBackground = 'assets/images/bg_artistic.png';

  // Theme-card frames (square floral frames)
  static const String frameLilyOfTheValley =
      'assets/images/frame_lilyofthevalley.png';
  static const String frameSakura = 'assets/images/frame_sakura.png';
  static const String frameFern = 'assets/images/frame_fern.png';
  static const String frameTropical = 'assets/images/frame_tropical.png';

  // Clue-card bodies (your 4 clue card looks)
  static const String clueTapedNote = 'assets/images/taped_note.png';
  static const String clueTargetFrame = 'assets/images/target_frame.png';
  static const String clueHangingTag = 'assets/images/hanging_tag.png';
  static const String clueFramedSheet = 'assets/images/framed_sheet.png';

  // New Clue Cards
  static const String clueOnepiece = 'assets/images/onepiece.png';
  static const String clueLight = 'assets/images/light.png';

  static const String stickyNoteYellow = 'assets/images/stickynote_yellow.png';
  static const String stickyNoteBlue = 'assets/images/stickynote_blue.png';
  static const String stickyNoteGreen = 'assets/images/stickynote_green.png';
  static const String stickyNotePink = 'assets/images/stickynote_pink.png';

  static const String totemCream = 'assets/images/totem_cream.png';
  static const String totemHeart = 'assets/images/totem_heart.png';
  static const String totemPink = 'assets/images/totem_pink.png';
  static const String totemShapeless = 'assets/images/totem_shapeless.png';

  final String id;
  final String name;

  // Background
  final Color backgroundColor;
  final String? backgroundTexture; // Asset path

  // Text colors
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;

  // Card styles (base styling)
  final CardStyle totemStyle;
  final CardStyle themeStyle;
  final CardStyle clueStyle;

  // Edge style (string lines)
  final Color edgeColor;
  final double edgeWidth;

  // New: asset pools for choosing variants in UI
  // Theme card frames: pick 1 of 4
  final List<String> themeFrameAssets;

  // Clue card bodies: pick 1 of 4
  final List<String> clueCardAssets;

  // Totem assets: pick 1 of 4
  final List<String> totemAssets;

  // Sticky note label used on theme cards
  final String stickyNoteAsset;

  const ThemePack({
    required this.id,
    required this.name,
    required this.backgroundColor,
    this.backgroundTexture,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.totemStyle,
    required this.themeStyle,
    required this.clueStyle,
    required this.edgeColor,
    this.edgeWidth = 2.0,
    required this.themeFrameAssets,
    required this.clueCardAssets,
    required this.totemAssets,
    required this.stickyNoteAsset,
  });

  /// Felt / detective wall (still can keep different palettes)
  factory ThemePack.vintage() {
    return const ThemePack(
      id: 'vintage',
      name: 'Detective Wall',
      backgroundColor: Color(0xFF3E2723),
      backgroundTexture: feltBackground,
      primaryTextColor: Color(0xFF1A1A1A),
      secondaryTextColor: Color(0xFF5D4037),
      accentColor: Color(0xFFB71C1C),
      edgeColor: Color(0xAAFFFFFF),

      // Totem card: you haven't provided totem assets yet, keep plain for now
      totemStyle: CardStyle(
        backgroundColor: Color(0xFF8D6E63),
        textColor: Colors.black, // Changed to black for paper-like assets
        fontFamily: 'Georgia',
        fontSize: 30.0,
        textureAsset: null,
      ),

      // Theme card: use frames + sticky label (textureAsset left null)
      themeStyle: CardStyle(
        backgroundColor: Color(0xFFFFFFFF),
        textColor: Color(0xFF3E2723),
        fontFamily: 'Georgia',
        fontSize: 24.0,
        textureAsset: null,
      ),

      // Clue card: use clue card assets (textureAsset left null)
      clueStyle: CardStyle(
        backgroundColor: Color(0xFFFFFFFF),
        textColor: Color(0xFF1A1A1A),
        fontFamily: 'Georgia',
        fontSize: 20.0,
        textureAsset: null,
      ),

      // Pools
      themeFrameAssets: <String>[
        stickyNoteYellow,
        stickyNoteBlue,
        stickyNoteGreen,
        stickyNotePink,
      ],
      clueCardAssets: <String>[
        // 4 basic clue cards
        clueTapedNote,
        clueTargetFrame,
        clueHangingTag,
        clueFramedSheet,
        // 4 floral frames
        frameLilyOfTheValley,
        frameSakura,
        frameFern,
        frameTropical,
        // New backgrounds
        clueOnepiece,
        clueLight,
      ],
      totemAssets: <String>[
        totemCream,
        totemHeart,
        totemPink,
        totemShapeless,
      ],
      stickyNoteAsset: stickyNoteYellow,
    );
  }

  factory ThemePack.fresh() {
    return const ThemePack(
      id: 'fresh',
      name: 'Fresh',
      backgroundColor: Color(0xFFF3F7F9),
      backgroundTexture: freshBackground,
      primaryTextColor: Color(0xFF1C2A33),
      secondaryTextColor: Color(0xFF4E6A7A),
      accentColor: Color(0xFF26A69A),
      edgeColor: Color(0xAA263238),
      totemStyle: CardStyle(
        backgroundColor: Color(0xFFFFFFFF),
        textColor: Color(0xFF1C2A33),
        fontFamily: 'Montserrat',
        fontSize: 30.0,
        textureAsset: null,
      ),
      themeStyle: CardStyle(
        backgroundColor: Color(0xFFFFFFFF),
        textColor: Color(0xFF1C2A33),
        fontFamily: 'Montserrat',
        fontSize: 24.0,
        textureAsset: null,
      ),
      clueStyle: CardStyle(
        backgroundColor: Color(0xFFFFFFFF),
        textColor: Color(0xFF1C2A33),
        fontFamily: 'Montserrat',
        fontSize: 20.0,
        textureAsset: null,
      ),
      themeFrameAssets: <String>[
        stickyNoteYellow,
        stickyNoteBlue,
        stickyNoteGreen,
        stickyNotePink,
      ],
      clueCardAssets: <String>[
        clueTapedNote,
        clueTargetFrame,
        clueHangingTag,
        clueFramedSheet,
        frameLilyOfTheValley,
        frameSakura,
        frameFern,
        frameTropical,
        // New backgrounds
        clueOnepiece,
        clueLight,
      ],
      totemAssets: <String>[
        totemCream,
        totemHeart,
        totemPink,
        totemShapeless,
      ],
      stickyNoteAsset: stickyNoteYellow,
    );
  }

  factory ThemePack.artistic() {
    return const ThemePack(
      id: 'artistic',
      name: 'Artistic',
      backgroundColor: Color(0xFF0B0F1A),
      backgroundTexture: artisticBackground,
      primaryTextColor: Colors.black,
      secondaryTextColor: Colors.black,
      accentColor: Color.fromARGB(255, 125, 190, 20),
      edgeColor: Color(0xAA00E5FF),
      totemStyle: CardStyle(
        backgroundColor: Color(0xFF0B0F1A),
        textColor: Colors.black,
        fontFamily: 'Orbitron',
        fontSize: 30.0,
        textureAsset: null,
      ),
      themeStyle: CardStyle(
        backgroundColor: Color(0xFF0B0F1A),
        textColor: Colors.black,
        fontFamily: 'Orbitron',
        fontSize: 24.0,
        textureAsset: null,
      ),
      clueStyle: CardStyle(
        backgroundColor: Color(0xFF0B0F1A),
        textColor: Colors.black,
        fontFamily: 'Orbitron',
        fontSize: 20.0,
        textureAsset: null,
      ),
      themeFrameAssets: <String>[
        stickyNoteYellow,
        stickyNoteBlue,
        stickyNoteGreen,
        stickyNotePink,
      ],
      clueCardAssets: <String>[
        clueTapedNote,
        clueTargetFrame,
        clueHangingTag,
        clueFramedSheet,
        frameLilyOfTheValley,
        frameSakura,
        frameFern,
        frameTropical,
        // New backgrounds
        clueOnepiece,
        clueLight,
      ],
      totemAssets: <String>[
        totemCream,
        totemHeart,
        totemPink,
        totemShapeless,
      ],
      stickyNoteAsset: stickyNoteYellow,
    );
  }
}

class CardStyle {
  final Color backgroundColor;
  final Color textColor;
  final String? fontFamily;
  final double fontSize;

  /// Optional: if later you still want a single texture overlay
  final String? textureAsset;

  const CardStyle({
    required this.backgroundColor,
    required this.textColor,
    this.fontFamily,
    this.fontSize = 20.0,
    this.textureAsset,
  });
}
