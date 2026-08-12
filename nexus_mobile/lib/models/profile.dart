class Profile {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isKids;
  final String? pinCode;

  Profile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isKids,
    this.pinCode,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      isKids: json['is_kids'] ?? false,
      pinCode: json['pin_code'],
    );
  }
}
