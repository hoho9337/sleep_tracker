import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:intl/intl.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    try {
      final requestData = await context.request.json() as Map<String, dynamic>;
      final alarmTime = requestData['alarmTime'] as String?;
      final username = requestData['username'] as String?;

      if (alarmTime == null || username == null) {
        print('Invalid request data: $requestData');
        return Response.json(
          statusCode: 400,
          body: {'error': 'Invalid request data'},
        );
      }

      final db = await Db.create('mongodb+srv://hoho:0000@sleepdb.pc6gp1r.mongodb.net/flutter_auth?retryWrites=true&w=majority');
      await db.open();
      final collection = db.collection('alarms');

      await collection.update(
        where.eq('username', username),
        modify.set('alarmTime', alarmTime),
        upsert: true,
      );

      await db.close();

      // Calculate the recommended sleep times
      final DateFormat format = DateFormat("h:mm a");
      final DateTime alarmDateTime = format.parse(alarmTime);

      final recommendedTimes = [
        format.format(alarmDateTime.subtract(Duration(hours: 9))),
        format.format(alarmDateTime.subtract(Duration(hours: 7, minutes: 30))),
        format.format(alarmDateTime.subtract(Duration(hours: 6))),
      ];

      return Response.json(
        body: {
          'message': 'Alarm time saved successfully',
          'recommendedTimes': recommendedTimes,
        },
      );
    } catch (e) {
      print('Error: $e');
      return Response.json(
        statusCode: 500,
        body: {'error': 'Internal server error', 'details': e.toString()},
      );
    }
  }

  return Response.json(
    statusCode: 405,
    body: {'error': 'Method not allowed'},
  );
}
