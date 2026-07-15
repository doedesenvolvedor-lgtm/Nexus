class Media {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final String banner;
  final String video;
  final String type;
  final String genre;
  final int? releaseYear;
  final int? duration;
  final String rating;

  Media({
    required this.id,
    required this.title,
    this.description = '',
    required this.thumbnail,
    required this.banner,
    required this.video,
    required this.type,
    this.genre = '',
    this.releaseYear,
    this.duration,
    this.rating = '',
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnail: json['thumbnail_url'] ?? '',
      banner: json['banner_url'] ?? '',
      video: json['video_url'] ?? '',
      type: json['content_type'] ?? '',
      genre: json['genre'] ?? '',
      releaseYear: json['release_year'] as int?,
      duration: json['duration'] as int?,
      rating: json['rating'] ?? '',
    );
  }
}
