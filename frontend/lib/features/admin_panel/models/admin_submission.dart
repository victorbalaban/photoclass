class AdminSubmission {
  final int id;
  final String classificationTitle;
  final DateTime timestamp;
  final String userName;
  final int userAge;
  final String userGender;
  final String userCountry;
  final String userPlaceOfLiving;
  final String imageUrl;

  AdminSubmission({
    required this.id,
    required this.classificationTitle,
    required this.timestamp,
    required this.userName,
    required this.userAge,
    required this.userGender,
    required this.userCountry,
    required this.userPlaceOfLiving,
    required this.imageUrl,
  });

  factory AdminSubmission.fromJson(Map<String, dynamic> json) {
    return AdminSubmission(
      id: json['id'],
      classificationTitle: json['classification_title'],
      timestamp: DateTime.parse(json['timestamp']),
      userName: json['user_name'],
      userAge: json['user_age'],
      userGender: json['user_gender'],
      userCountry: json['user_country'],
      userPlaceOfLiving: json['user_place_of_living'],
      imageUrl: json['image_url'] ?? '',
    );
  }
}