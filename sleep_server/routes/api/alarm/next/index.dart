import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:intl/intl.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.get) {
    try {
      final db = await Db.create('mongodb+srv://hoho:0000@sleepdb.pc6gp1r.mongodb.net/flutter_auth?retryWrites=true&w=majority');
      await db.open();
      final collection = db.collection('alarms');

      final alarm = await collection.findOne();
      await db.close();

      if (alarm != null) {
        final alarmTime = alarm['alarmTime'];
        final DateFormat format = DateFormat('h:mm a');
        final DateTime alarmDateTime = format.parse(alarmTime.toString());

        final recommendedTimes = [
          format.format(alarmDateTime.subtract(Duration(hours: 9))),
          format.format(alarmDateTime.subtract(Duration(hours: 7, minutes: 30))),
          format.format(alarmDateTime.subtract(Duration(hours: 6))),
        ];

        return Response.json(
          body: {
            'nextAlarmTime': alarmTime,
            'recommendedTimes': recommendedTimes,
          },
        );
      } else {
        return Response.json(
          statusCode: 404,
          body: {'error': 'No alarm found'},
        );
      }
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
