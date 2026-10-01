class CategorySubCategoryTopicModel {
  bool? status;
  String? message;
  List<Category>? data;

  CategorySubCategoryTopicModel({this.status, this.message, this.data});

  factory CategorySubCategoryTopicModel.fromJson(Map<String, dynamic> json) =>
      CategorySubCategoryTopicModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Category>.from(
                json["data"].map((x) => Category.fromJson(x))),
      );
}

class Category {
  int? id;
  String? name;
  List<SubCategory>? subCategories;

  Category({this.id, this.name, this.subCategories});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json["id"],
        name: json["name"],
        subCategories: json["sub_categories"] == null
            ? []
            : List<SubCategory>.from(
                json["sub_categories"].map((x) => SubCategory.fromJson(x))),
      );
}

class SubCategory {
  int? id;
  String? name;
  int? categoryId;
  List<Division>? divisions;
  List<Topic>? topics;

  SubCategory({this.id, this.name, this.categoryId, this.divisions, this.topics});

  factory SubCategory.fromJson(Map<String, dynamic> json) => SubCategory(
        id: json["id"],
        name: json["name"],
        categoryId: json["category_id"],
        divisions: json["divisions"] == null
            ? []
            : List<Division>.from(
                json["divisions"].map((x) => Division.fromJson(x))),
        topics: json["topics"] == null
            ? []
            : List<Topic>.from(
                json["topics"].map((x) => Topic.fromJson(x))),
      );
}

class Division {
  int? id;
  String? name;
  int? subCategoryId;
  int? categoryId;

  Division({this.id, this.name, this.subCategoryId, this.categoryId});

  factory Division.fromJson(Map<String, dynamic> json) => Division(
        id: json["id"],
        name: json["name"],
        subCategoryId: json["sub_category_id"],
        categoryId: json["category_id"],
      );
}

class Topic {
  int? id;
  String? name;
  int? subCategoryId;
  int? divisionId;

  Topic({this.id, this.name, this.subCategoryId, this.divisionId});

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json["id"],
        name: json["name"],
        subCategoryId: json["sub_category_id"],
        divisionId: json["division_id"],
      );
}