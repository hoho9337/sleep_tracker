import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.get) {
    final db = await Db.create('mongodb+srv://hoho:0000@sleepdb.pc6gp1r.mongodb.net/flutter_auth?retryWrites=true&w=majority');
    await db.open();
    final collection = db.collection('sleep_data');

    final sleepData = await collection.find().toList();
    await db.close();

    return Response.json(
      body: sleepData,
    );
  }

  return Response.json(
    statusCode: 405,
    body: {'error': 'Method not allowed'},
  );
}
