import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:citystat1/src/constants.dart';

final hmacSha1 = Hmac(sha1, utf8.encode(kLichessWSSecret));

/// Sign a bearer token with the Lichess secret.
String signBearerToken(String token) {
  final digest = hmacSha1.convert(utf8.encode(token));
  return '$token:$digest';
}
