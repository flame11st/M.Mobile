class Person {
    final name;

    Person({this.name});

    factory Person.fromJson(Map<String, dynamic> json) {
        return Person(name: json['name']);
    }
}