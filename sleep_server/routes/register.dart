import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

Future<Response> onRequest(RequestContext context) async {
  final db = await mongo.Db.create(
      'mongodb+srv://hoho:0000@sleepdb.pc6gp1r.mongodb.net/flutter_auth?retryWrites=true&w=majority');
  await db.open();
  final collection = db.collection('user');

  if (context.request.method == HttpMethod.post) {
    final data = await context.request.json() as Map<String, dynamic>;
    final username = data['username'] as String;
    final password = data['password'] as String;

    final user = await collection.findOne(mongo.where.eq('username', username));
    if (user != null) {
      await db.close();
      return Response.json(
          body: {'error': 'User already exists'},
          statusCode: HttpStatus.conflict);
    } else {
      await collection.insert({'username': username, 'password': password});
      await db.close();
      return Response.json(
          body: {'message': 'Registration successful'},
          statusCode: HttpStatus.ok);
    }
  }

  await db.close();
  return Response(statusCode: HttpStatus.methodNotAllowed);
}
