class CategoryModel {
  final String id;
  final String nameArabic;
  final String descriptionArabic;
  final String colorHex;
  final String icon;

  const CategoryModel({
    required this.id,
    required this.nameArabic,
    required this.descriptionArabic,
    required this.colorHex,
    required this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      nameArabic: json['nameArabic'] as String,
      descriptionArabic: json['descriptionArabic'] as String,
      colorHex: json['colorHex'] as String,
      icon: json['icon'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameArabic': nameArabic,
      'descriptionArabic': descriptionArabic,
      'colorHex': colorHex,
      'icon': icon,
    };
  }
}
