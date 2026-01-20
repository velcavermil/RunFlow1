class UserModel {
  final String name;

  UserModel({required this.name});

  Map<String, dynamic> toMap() => {
        'name': name,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'],
    );
  }
}
