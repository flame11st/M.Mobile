class User {
    String name;
    final role;
    String email;
    final id;

    User({this.name, this.role, this.email, this.id});

    factory User.fromJson(Map<String, dynamic> json) {
        return User(
            name: json['name'],
            email: json['email'],
            role: json['role'],
            id: json['id'],
        );
    }
}