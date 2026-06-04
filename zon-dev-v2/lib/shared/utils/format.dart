/// Compact, human-friendly count: 999 · 1.2k · 3.4M.
String compactCount(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) {
    final k = n / 1000;
    return '${k.toStringAsFixed(n % 1000 >= 100 ? 1 : 0)}k';
  }
  return '${(n / 1000000).toStringAsFixed(1)}M';
}
