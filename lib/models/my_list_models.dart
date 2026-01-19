class SavedStore {
  final String id;
  final String name;
  final String? address;

  const SavedStore({
    required this.id,
    required this.name,
    this.address,
  });
}

class MyList {
  final String id;
  final String name;
  final List<String> storeIds;
  final DateTime createdAt;

  const MyList({
    required this.id,
    required this.name,
    required this.storeIds,
    required this.createdAt,
  });

  MyList copyWith({
    String? id,
    String? name,
    List<String>? storeIds,
    DateTime? createdAt,
  }) {
    return MyList(
      id: id ?? this.id,
      name: name ?? this.name,
      storeIds: storeIds ?? this.storeIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
