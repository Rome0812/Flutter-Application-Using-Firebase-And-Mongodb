class User {
  final String uid;
  final String firstName;
  final String lastName;
  final String age;
  final String gender;
  final String contactNumber;
  final String email;
  final String username;
  final String address;
  final bool isActive;
  final String type;

  User({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.gender,
    required this.contactNumber,
    required this.email,
    required this.username,
    required this.address,
    required this.isActive,
    required this.type,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid']?.toString() ?? json['_id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      age: json['age']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      contactNumber: json['contactNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      isActive: json['isActive'] == true,
      type: json['type']?.toString() ?? '',
    );
  }
}
