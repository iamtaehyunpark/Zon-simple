/// Validate a user ID (handle). Returns a user-facing error string, or null
/// when [id] is a well-formed ID. Uniqueness is checked separately against the
/// database; this only covers format. 3–20 chars, lowercase letters/digits/._.
String? usernameError(String id) {
  final v = id.trim();
  if (v.isEmpty) return 'ID can\'t be empty';
  if (v.length < 3) return 'ID must be at least 3 characters';
  if (v.length > 20) return 'ID must be 20 characters or fewer';
  if (!RegExp(r'^[a-z0-9._]+$').hasMatch(v)) {
    return 'Use lowercase letters, numbers, . or _';
  }
  return null;
}

/// Compact, human-friendly count: 999 · 1.2k · 3.4M.
String compactCount(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) {
    final k = n / 1000;
    return '${k.toStringAsFixed(n % 1000 >= 100 ? 1 : 0)}k';
  }
  return '${(n / 1000000).toStringAsFixed(1)}M';
}
