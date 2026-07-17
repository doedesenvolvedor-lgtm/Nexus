// Models de dados para Nexustwos

class User {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final String? planId;
  final DateTime? trialEndDate;
  final DateTime createdAt;
  final bool isPremium;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    this.planId,
    this.trialEndDate,
    required this.createdAt,
    this.isPremium = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      planId: json['plan_id'],
      trialEndDate: json['trial_end_date'] != null
          ? DateTime.parse(json['trial_end_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isPremium: json['is_premium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'avatar': avatar,
    'plan_id': planId,
    'trial_end_date': trialEndDate?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'is_premium': isPremium,
  };
}

class Media {
  final String id;
  final String title;
  final String description;
  final String? posterUrl;
  final String? bannerUrl;
  final String? videoUrl;
  final int year;
  final String genre;
  final double rating;
  final String duration;
  final String type; // 'movie' or 'series'
  final List<String> categories;
  final bool isFavorite;
  final int? episodeCount;
  final String? ageRating;

  Media({
    required this.id,
    required this.title,
    required this.description,
    this.posterUrl,
    this.bannerUrl,
    this.videoUrl,
    required this.year,
    required this.genre,
    required this.rating,
    required this.duration,
    required this.type,
    this.categories = const [],
    this.isFavorite = false,
    this.episodeCount,
    this.ageRating,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      posterUrl: json['poster_url'],
      bannerUrl: json['banner_url'],
      videoUrl: json['video_url'],
      year: json['year'] ?? DateTime.now().year,
      genre: json['genre'] ?? 'Unknown',
      rating: (json['rating'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? '0h',
      type: json['type'] ?? 'movie',
      categories: List<String>.from(json['categories'] ?? []),
      isFavorite: json['is_favorite'] ?? false,
      episodeCount: json['episode_count'],
      ageRating: json['age_rating'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'poster_url': posterUrl,
    'banner_url': bannerUrl,
    'video_url': videoUrl,
    'year': year,
    'genre': genre,
    'rating': rating,
    'duration': duration,
    'type': type,
    'categories': categories,
    'is_favorite': isFavorite,
    'episode_count': episodeCount,
    'age_rating': ageRating,
  };
}

class Subscription {
  final String id;
  final String name;
  final double price;
  final int screens;
  final String maxQuality;
  final List<String> features;
  final bool isPopular;

  Subscription({
    required this.id,
    required this.name,
    required this.price,
    required this.screens,
    required this.maxQuality,
    this.features = const [],
    this.isPopular = false,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      screens: json['screens'] ?? 1,
      maxQuality: json['max_quality'] ?? 'HD',
      features: List<String>.from(json['features'] ?? []),
      isPopular: json['is_popular'] ?? false,
    );
  }
}

class Episode {
  final String id;
  final String seriesId;
  final int season;
  final int episodeNumber;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final int duration; // in seconds
  final DateTime releaseDate;
  final double? rating;

  Episode({
    required this.id,
    required this.seriesId,
    required this.season,
    required this.episodeNumber,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.videoUrl,
    required this.duration,
    required this.releaseDate,
    this.rating,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] ?? '',
      seriesId: json['series_id'] ?? '',
      season: json['season'] ?? 1,
      episodeNumber: json['episode_number'] ?? 1,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      videoUrl: json['video_url'],
      duration: json['duration'] ?? 0,
      releaseDate: json['release_date'] != null
          ? DateTime.parse(json['release_date'])
          : DateTime.now(),
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }
}

class WatchHistory {
  final String mediaId;
  final String mediaTitle;
  final String? posterUrl;
  final int watchedDuration; // in seconds
  final int totalDuration; // in seconds
  final DateTime lastWatched;

  WatchHistory({
    required this.mediaId,
    required this.mediaTitle,
    this.posterUrl,
    required this.watchedDuration,
    required this.totalDuration,
    required this.lastWatched,
  });

  double get progress => totalDuration > 0 ? watchedDuration / totalDuration : 0;

  factory WatchHistory.fromJson(Map<String, dynamic> json) {
    return WatchHistory(
      mediaId: json['media_id'] ?? '',
      mediaTitle: json['media_title'] ?? '',
      posterUrl: json['poster_url'],
      watchedDuration: json['watched_duration'] ?? 0,
      totalDuration: json['total_duration'] ?? 0,
      lastWatched: json['last_watched'] != null
          ? DateTime.parse(json['last_watched'])
          : DateTime.now(),
    );
  }
}

class Payment {
  final String id;
  final String userId;
  final String subscriptionId;
  final double amount;
  final String status; // 'pending', 'approved', 'rejected', 'cancelled'
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? paymentMethod;

  Payment({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.paymentMethod,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      subscriptionId: json['subscription_id'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      paymentMethod: json['payment_method'],
    );
  }
}

class Notification {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;
  final String? actionUrl;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.createdAt,
    this.isRead = false,
    this.actionUrl,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      actionUrl: json['action_url'],
    );
  }
}

class Profile {
  final String id;
  final String userId;
  final String name;
  final String? avatar;
  final bool isKidProfile;
  final bool isAdult;

  Profile({
    required this.id,
    required this.userId,
    required this.name,
    this.avatar,
    this.isKidProfile = false,
    this.isAdult = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      isKidProfile: json['is_kid_profile'] ?? false,
      isAdult: json['is_adult'] ?? false,
    );
  }
}
