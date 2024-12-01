import 'package:http/http.dart';
import 'package:odometer_app/api_request_helper.dart';
import 'dart:convert';

class Vehicle 
{
  const Vehicle({required this.id, required this.make, required this.model, required this.year});
  final String id;
  final String make;
  final String model;
  final int year;
  
  static Future<Vehicle?> onlineRequest(String id) async
  {
    Client client = Client();

    final Response response = await client.get(Uri.parse("https://api.smartcar.com/v2.0/vehicles/$id"),
      headers: {
        'Authorization': 'Bearer ${APIRequestHelper.instance.accessToken!.value}'
      }
    );

    if(response.statusCode == 200)
    {
      var data = json.decode(response.body);
      return Vehicle(id: data['id'], make: data['make'], model: data['model'], year: data['year']);
    }

    print("Respuesta vehiculo $id: " + response.statusCode.toString());
    return null;
  }
}