import 'dart:math';
import '../model/interest_search_item.dart';

class FuzzyMatchResult {
  final InterestSearchItem item;
  final int score;
  final int distance;

  FuzzyMatchResult({
    required this.item,
    required this.score,
    required this.distance,
  });
}

class FuzzySearchUtil {
  /// Computes Damerau-Levenshtein distance (insertions, deletions, substitutions, transpositions)
  static int editDistance(String s1, String s2) {
    final a = s1.toLowerCase();
    final b = s2.toLowerCase();
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final d = List.generate(
      a.length + 1,
      (i) => List<int>.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      d[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
        d[i][j] = min(
          d[i - 1][j] + 1, // deletion
          min(
            d[i][j - 1] + 1, // insertion
            d[i - 1][j - 1] + cost, // substitution
          ),
        );
        // Transposition
        if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) {
          d[i][j] = min(d[i][j], d[i - 2][j - 2] + 1);
        }
      }
    }
    return d[a.length][b.length];
  }

  /// Calculates a relevance score for [query] against [target].
  /// Higher score = better match. Returns null if not a match.
  static int? matchScore(String query, String target) {
    final q = query.trim().toLowerCase();
    final t = target.trim().toLowerCase();
    if (q.isEmpty || t.isEmpty) return null;

    // 1. Exact match
    if (q == t) return 1000;

    // 2. Exact prefix match (e.g. "sci" -> "science")
    if (t.startsWith(q)) {
      return 850 - (t.length - q.length);
    }

    // 3. Word-level prefix match (e.g. "Computer Science" -> "sci")
    final words = t.split(RegExp(r'[\s\-_/]+'));
    for (final w in words) {
      if (w.startsWith(q)) {
        return 800 - (w.length - q.length);
      }
    }

    // 4. Substring match
    if (t.contains(q)) {
      final index = t.indexOf(q);
      return 700 - (index * 5);
    }

    // 5. Typo-tolerant fuzzy match (e.g. "scienc" -> "science", "sciencee" -> "science")
    if (q.length >= 3) {
      final distance = editDistance(q, t);

      // Distance of 1 (single typo / missing / extra letter)
      if (distance == 1) {
        return 650;
      }

      // Distance of 2 for words of length >= 5
      if (distance == 2 && q.length >= 5) {
        return 550;
      }

      // Prefix typo: compare query with target's prefix of same length
      if (t.length >= q.length) {
        final prefix = t.substring(0, q.length);
        final prefixDist = editDistance(q, prefix);
        if (prefixDist == 1) {
          return 620;
        }
      }
    }

    return null;
  }

  /// Finds and ranks matching Interest items for the given query
  static List<InterestSearchItem> findSuggestions(
    String query,
    List<InterestSearchItem> catalog, {
    int maxResults = 8,
  }) {
    final q = query.trim();
    if (q.isEmpty) return [];

    final matches = <FuzzyMatchResult>[];
    final seenNames = <String>{};

    for (final item in catalog) {
      final normalizedName = item.name.toLowerCase().trim();
      if (seenNames.contains(normalizedName)) continue;

      int highestScore = -1;
      int bestDist = 99;

      // Check primary item name
      final primaryScore = matchScore(q, item.name);
      if (primaryScore != null && primaryScore > highestScore) {
        highestScore = primaryScore;
        bestDist = editDistance(q, item.name);
      }

      // Also check related keywords
      for (final kw in item.relatedKeywords) {
        final kwScore = matchScore(q, kw);
        if (kwScore != null) {
          final adjusted = kwScore - 40;
          if (adjusted > highestScore) {
            highestScore = adjusted;
            bestDist = min(bestDist, editDistance(q, kw));
          }
        }
      }

      if (highestScore > 0) {
        seenNames.add(normalizedName);
        matches.add(FuzzyMatchResult(
          item: item,
          score: highestScore,
          distance: bestDist,
        ));
      }
    }

    // Sort by score descending, then distance ascending
    matches.sort((a, b) {
      if (a.score != b.score) {
        return b.score.compareTo(a.score);
      }
      return a.distance.compareTo(b.distance);
    });

    return matches.take(maxResults).map((m) => m.item).toList();
  }
}
