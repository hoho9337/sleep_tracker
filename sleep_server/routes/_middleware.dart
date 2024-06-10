import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return (context) async {
    if (context.request.method == HttpMethod.options) {
      return Response(
        statusCode: HttpStatus.noContent,
        headers: {
          HttpHeaders.accessControlAllowOriginHeader: '*',
          HttpHeaders.accessControlAllowMethodsHeader: 'GET, POST, OPTIONS',
          HttpHeaders.accessControlAllowHeadersHeader: 'Content-Type',
        },
      );
    }

    final response = await handler(context);

    return response.copyWith(
      headers: {
        ...response.headers,
        HttpHeaders.accessControlAllowOriginHeader: '*',
        HttpHeaders.accessControlAllowMethodsHeader: 'GET, POST, OPTIONS',
        HttpHeaders.accessControlAllowHeadersHeader: 'Content-Type',
      },
    );
  };
}
