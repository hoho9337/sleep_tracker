import 'package:mongo_dart/mongo_dart.dart';

class User {
  final String id;
  final String username;
  final String password;

  User({required this.id, required this.username, required this.password});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'].toString(),
      username: map['username'].toString(),
      password: map['password'].toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': ObjectId.fromHexString(id),
      'username': username,
      'password': password,
    };
  }
}
