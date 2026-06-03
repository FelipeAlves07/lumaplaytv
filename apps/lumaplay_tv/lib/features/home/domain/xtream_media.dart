class XtreamMedia {
  final String id;
  final String title;
  final String categoryId;
  final String categoryName;
  final String posterUrl;
  final String rating;
  final String year;
  final String streamType;
  final String containerExtension;
  final String streamUrl;

  const XtreamMedia({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.posterUrl,
    required this.rating,
    required this.year,
    required this.streamType,
    required this.containerExtension,
    required this.streamUrl,
  });

  factory XtreamMedia.fromJson(
    Map<String, dynamic> json, {
    Map<String, String> categories = const {},
  }) {
    final categoryId = json['category_id']?.toString() ?? '';

    return XtreamMedia(
      id: json['stream_id']?.toString() ??
          json['series_id']?.toString() ??
          json['id']?.toString() ??
          '',
      title: json['name']?.toString() ??
          json['title']?.toString() ??
          'Sem título',
      categoryId: categoryId,
      categoryName: categories[categoryId] ??
          json['category_name']?.toString() ??
          '',
      posterUrl: json['stream_icon']?.toString() ??
          json['cover']?.toString() ??
          json['cover_big']?.toString() ??
          '',
      rating: json['rating']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      streamType: json['stream_type']?.toString() ?? '',
      containerExtension: json['container_extension']?.toString() ?? 'mp4',
      streamUrl: json['streamUrl']?.toString() ?? '',
    );
  }
}
