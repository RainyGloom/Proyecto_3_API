import 'package:http/http.dart';
import 'package:odometer_app/api_request_helper.dart';
import 'dart:convert';
class User {
  const User({required this.id});

  final String id;

  Map<String, Object> toMap()
  {
    return
    {
      'id': id
    };
  }
}