class Store {
  final int rank;
  final String name;
  final double distance;
  final int reviewCount;
  final double needsFineScore;
  final List<String> tags;

  Store({
    required this.rank,
    required this.name,
    required this.distance,
    required this.reviewCount,
    required this.needsFineScore,
    required this.tags,
  });
}
