class UserModel {
  final String username;
  final String password;
  final String name;
  final int age;
  final String gender;
  final String placeOfLiving;
  final String countryCode;
  final String? description;

  UserModel({
    required this.username,
    required this.password,
    required this.name,
    required this.age,
    required this.gender,
    required this.placeOfLiving,
    required this.countryCode,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'name': name,
      'age': age,
      'gender': gender,
      'place_of_living': placeOfLiving,
      'country_code': countryCode,
      'description': description,
    };
  }
}