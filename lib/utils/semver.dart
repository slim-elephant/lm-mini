/// Compare two semantic versions (`1.9.0`, `1.8.25+116`).
///
/// Returns positive if [a] > [b], negative if [a] < [b], 0 if equal.
/// Build (`+n`) and prerelease (`-beta`) suffixes are ignored.
int compareSemver(String a, String b) {
  List<int> parse(String v) => v
      .split(RegExp('[+-]'))
      .first
      .split('.')
      .map((s) => int.tryParse(s) ?? 0)
      .toList();
  final pa = parse(a);
  final pb = parse(b);
  final len = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < len; i++) {
    final na = i < pa.length ? pa[i] : 0;
    final nb = i < pb.length ? pb[i] : 0;
    if (na != nb) return na - nb;
  }
  return 0;
}

/// True when [a] semver-precedes [b] (e.g. `1.8.25` < `1.9.0`).
bool semverLess(String a, String b) => compareSemver(a, b) < 0;
