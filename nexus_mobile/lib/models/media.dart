class Media {
  final String id;
  final String title;
  final String thumbnail;
  final String banner;
  final String video;
  final String type;

  Media({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.banner,
    required this.video,
    required this.type,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      thumbnail: json['thumbnail_url'] ?? '',
      banner: json['banner_url'] ?? '',
      video: json['video_url'] ?? '',
      type: json['content_type'] ?? '',
    );
  }
}
