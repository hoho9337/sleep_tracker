import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';

Handler middleware(Handler handler) {
  return (context) async {
    final db = await Db.create(
        'mongodb+srv://hoho:0000@sleepdb.pc6gp1r.mongodb.net/flutter_auth?retryWrites=true&w=majority&appName=SleepDB');

    if (!db.isConnected) {
      await db.open();
    }

    final response = await handler.use(provider<Db>((_) => db)).call(context);

    await db.close;

    return response;
  };
}
