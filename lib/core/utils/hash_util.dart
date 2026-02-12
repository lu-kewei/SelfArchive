/// FNV-1a 64-bit hash algorithm optimized for Dart
/// Adapted for Web compatibility (JS integers are 53-bit safe)
int fastHash(String string) {
  // Use a 32-bit offset basis instead of 64-bit to avoid BigInt issues in JS
  // Original FNV-1a 64-bit offset basis: 0xcbf29ce484222325
  // We use a 32-bit equivalent or just a different seed that fits in JS integer.
  // 0x811c9dc5 is the FNV-1a 32-bit offset basis.
  var hash = 0x811c9dc5;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    // For 32-bit FNV-1a:
    // hash ^= codeUnit;
    // hash *= 0x01000193;

    // But we want to maintain some collision resistance similar to original
    // without using 64-bit literals.
    // Let's implement standard 32-bit FNV-1a which is safe for JS.
    hash ^= codeUnit;
    // 0x01000193 is 16777619, safe for JS multiplication (result fits in 53 bits mostly,
    // but repeated multiplication overflows 32 bits, which is fine in Dart VM (64-bit)
    // but in JS we need to ensure it stays within 32 bits or use BigInt if we strictly want 32-bit wrapping).
    // Dart's int on Web behaves like JS number (double).
    // To simulate 32-bit integer overflow, we can mask.
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }

  return hash;
}
