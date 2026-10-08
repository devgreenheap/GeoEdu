enum InterestItemType {
  category,
  subCategory,
  division,
  topic,
  interest,
}

class InterestSearchItem {
  final String name;
  final InterestItemType type;
  final int? id;
  final String? parentCategoryName;
  final String? parentSubCategoryName;
  final String? parentDivisionName;
  final Set<String> relatedKeywords;

  InterestSearchItem({
    required this.name,
    required this.type,
    this.id,
    this.parentCategoryName,
    this.parentSubCategoryName,
    this.parentDivisionName,
    required this.relatedKeywords,
  });

  String get typeLabel {
    switch (type) {
      case InterestItemType.category:
        return 'Category';
      case InterestItemType.subCategory:
        return 'Subcategory';
      case InterestItemType.division:
        return 'Division';
      case InterestItemType.topic:
        return 'Topic';
      case InterestItemType.interest:
        return 'Interest';
    }
  }

  String get hierarchyBreadcrumb {
    final parts = <String>[];
    if (parentCategoryName != null && parentCategoryName != name) {
      parts.add(parentCategoryName!);
    }
    if (parentSubCategoryName != null && parentSubCategoryName != name) {
      parts.add(parentSubCategoryName!);
    }
    if (parentDivisionName != null && parentDivisionName != name) {
      parts.add(parentDivisionName!);
    }
    return parts.join(' > ');
  }
}
