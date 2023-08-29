class User {
  String name;
  final role;
  String email;
  final id;
  bool premiumPurchased;
  bool isIncognito;

  User(
      {required this.name,
      this.role,
      required this.email,
      this.id,
      required this.premiumPurchased,
      required this.isIncognito});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      email: json['email'],
      role: json['role'],
      id: json['id'],
      premiumPurchased: json['premiumPurchased'],
      isIncognito: json['isIncognito'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'premiumPurchased': premiumPurchased,
        'isIncognito': isIncognito
      };
}
