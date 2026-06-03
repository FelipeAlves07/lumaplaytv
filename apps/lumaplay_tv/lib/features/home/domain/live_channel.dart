class LiveChannel {
  final String name;
  final String category;
  final String logoUrl;
  final String streamUrl;

  const LiveChannel({
    required this.name,
    required this.category,
    required this.logoUrl,
    required this.streamUrl,
  });

  bool get hasLogo => logoUrl.trim().isNotEmpty;
}