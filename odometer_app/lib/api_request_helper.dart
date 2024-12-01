import 'package:odometer_app/content/vehicle.dart';
import 'package:http/http.dart';
import 'dart:convert';

class AccessToken
{
  const AccessToken({required this.value, required this.type, required this.expiresIn, required this.refreshValue});
  final String value;
  final String type;
  final int expiresIn;
  final String refreshValue;
}
class APIRequestHelper {
  
  APIRequestHelper({required this.clientId, required this.clientSecret, required this.uri})
  {
    instance = this;
  }

  final String uri;
  final String clientId;
  final String clientSecret;
  List<Vehicle> vehicles = [];
  String? authCode;
  AccessToken? accessToken;
  static late APIRequestHelper instance;
  
  static Future<void> loadVehicles() async
  {
    Client client = Client();

    final Response response = await client.get(Uri.parse("https://api.smartcar.com/v2.0/vehicles"),
      headers: {
        'Authorization': 'Bearer ${APIRequestHelper.instance.accessToken!.value}'
      }
    );

    if(response.statusCode == 200)
    {
      var data = json.decode(response.body);
      print(data['vehicles'].length);
      for(int i = 0; i < data['vehicles'].length; i++)
      {
        Vehicle? vehicle;
        do
        {
          vehicle = await Vehicle.onlineRequest(data['vehicles'][0]);
          if(vehicle != null)
          {
            APIRequestHelper.instance.vehicles.add(vehicle);
            print(vehicle.id);
          }
        }while(vehicle == null);
      }
      print(data.toString());
    }
  }

  static Future<double?> getOdometerDistance(String id) async
  {
    Client client = Client();

    final Response response = await client.get(Uri.parse("https://api.smartcar.com/v2.0/vehicles/$id/odometer"),
      headers: {
        'Authorization': 'Bearer ${APIRequestHelper.instance.accessToken!.value}'
      }
    );

    print("Respuesta odometro: ${response.statusCode}");
    if(response.statusCode == 200)
    {
      var data = json.decode(response.body);
      var value = data['distance'];

      switch(value)
      {
        case int i: return i.toDouble();
        case double d: return d;
        case String s: return double.parse(s);
      }
    }

    return null;
  }
}