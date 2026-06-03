class XtreamCategory {
  final String id;
  final String name;

  const XtreamCategory({
    required this.id,
    required this.name,
  });

  factory XtreamCategory.fromJson(Map<String, dynamic> json) {
    return XtreamCategory(
      id: json['category_id']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['category_name']?.toString() ??
          json['name']?.toString() ??
          'Sem categoria',
    );
  }
}
