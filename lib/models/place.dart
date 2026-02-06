class Place {
  final String name;
  final String? address;
  final double? rating;
  final int? userRatingsTotal;
  final String? icon;

  Place({
    required this.name,
    this.address,
    this.rating,
    this.userRatingsTotal,
    this.icon,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      name: json['name'],
      address: json['vicinity'],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      userRatingsTotal: json['user_ratings_total'],
      icon: json['icon'],
    );
  }
}
