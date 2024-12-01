import 'package:http/http.dart';
import 'package:odometer_app/api_request_helper.dart';
import 'dart:convert';

class Vehicle 
{
  const Vehicle({required this.userID, required this.id, required this.make, required this.model, required this.year});
  final String userID;
  final String id;
  final String make;
  final String model;
  final int year;
  
  Map<String, Object> toMap()
  {
    return 
    {
      'userID': userID,
      'id': id,
      'make': make,
      'model': model,
      'year': year,
    };
  }
}