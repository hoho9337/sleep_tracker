import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    final db = await mongo.Db.create(
        'mongodb+srv://hoho:0000@sleepdb.pc6gp1r.mongodb.net/flutter_auth?retryWrites=true&w=majority');
    await db.open();
    final collection = db.collection('user');

    final data = await context.request.json() as Map<String, dynamic>;
    final username = data['username'] as String;
    final password = data['password'] as String;

    final user = await collection
        .findOne(mongo.where.eq('username', username).eq('password', password));

    await db.close();

    if (user != null) {
      return Response.json(
          body: {'message': 'Login successful'}, statusCode: HttpStatus.ok);
    } else {
      return Response.json(
          body: {'error': 'Invalid username or password'},
          statusCode: HttpStatus.unauthorized);
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
