// import 'dart:convert';
//
// abstract class Model<T> {
//   T parseOne(String body);
//
//   List<T> parseMany(String body) {
//     final decoded = jsonDecode(body) as List<Object?>;
//
//     final parsed = decoded.cast<Map<String, Object?>>();
//
//     return parsed.map<T>(T.fromJson).toList();
//   }
// }
