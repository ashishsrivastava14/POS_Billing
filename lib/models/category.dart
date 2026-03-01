class Category {
  final String id;
  final String name;
  final String? parentId;
  final bool isActive;
  final int productCount;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.isActive = true,
    this.productCount = 0,
  });

  Category copyWith({
    String? id,
    String? name,
    String? parentId,
    bool? isActive,
    int? productCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      isActive: isActive ?? this.isActive,
      productCount: productCount ?? this.productCount,
    );
  }
}
