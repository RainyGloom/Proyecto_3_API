import 'package:odometer_app/content/vehicle.dart';
import 'content/user.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'api_database_helper.dart';

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
  User? user;
  List<Vehicle> vehicles = [];
  String? authCode;
  AccessToken? accessToken;
  static late APIRequestHelper instance;

  bool isConnected() => accessToken != null;
  
  static Future<void> getAccessToken() async
  {
    Client client = Client();

    var authEncode = base64.encode(utf8.encode('${APIRequestHelper.instance.clientId}:${APIRequestHelper.instance.clientSecret}'));
    final Response response = await client.post(Uri.parse('https://auth.smartcar.com/oauth/token'), headers: 
      {
        'Authorization': 'Basic $authEncode',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=authorization_code&code=${APIRequestHelper.instance.authCode}&redirect_uri=${APIRequestHelper.instance.uri}'
    );

    if(response.statusCode == 200)
    {
      final data = json.decode(response.body);
      APIRequestHelper.instance.accessToken = AccessToken(
        value: data['access_token'], 
        type:  data['token_type'], 
        expiresIn: data['expires_in'], 
        refreshValue: data['refresh_token']
      );
    }

    print("Response: " + response.statusCode.toString());
  }
  
  static Future<void> loadVehicles() async
  {
    if(!instance.isConnected())
    {
      return;
    }

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
          vehicle = await getVehicle(data['vehicles'][0]);
          if(vehicle != null)
          {
            APIRequestHelper.instance.vehicles.add(vehicle);
            print(vehicle.id);
          }
        }while(vehicle == null);
      }

      List<Vehicle> vehicles = await APIDatabaseHelper.getVehicles();

      for(int i = 0; i < vehicles.length; i++)
      {
        await APIDatabaseHelper.insertVehicle(vehicles[i]);
      }
      print(data.toString());
    }
  }

  static Future<double?> getSpeedometer(Vehicle vehicle) async
  {
    if(!instance.isConnected())
    {
      return 0;
    }

    Client client = Client();

    final Response response = await client.get(Uri.parse("https://api.smartcar.com/v2.0/vehicles/${vehicle.id}/${vehicle.make}/speedometer"),
      headers: {
        'Authorization': 'Bearer ${APIRequestHelper.instance.accessToken!.value}'
      }
    );

    print("Respuesta velocimetro: ${response.statusCode}");
    if(response.statusCode == 200)
    {
      var data = json.decode(response.body);
      var value = data['speed'];

      switch(value)
      {
        case int i: return i.toDouble();
        case double d: return d;
        case String s: return double.parse(s);
      }
    }

    return null;
  }

  static Future<double?> getOdometer(Vehicle vehicle) async
  {
    if(!instance.isConnected())
    {
      return 0;
    }

    Client client = Client();

    final Response response = await client.get(Uri.parse("https://api.smartcar.com/v2.0/vehicles/${vehicle.id}/odometer"),
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

  static Future<void> loadUser() async
  {
    if(!instance.isConnected())
    {
      return;
    }

    Client client = Client();

    final Response response = await client.get(Uri.parse("https://api.smartcar.com/v2.0/user"),
      headers: {
        'Authorization': 'Bearer ${APIRequestHelper.instance.accessToken!.value}'
      }
    );

    if(response.statusCode == 200)
    {
      var data = json.decode(response.body);
      User user = User(id: data['id']);
      List<User> users = await APIDatabaseHelper.getUsers();
      bool newUser = true;
      for(int i = 0; i < users.length; i++)
      {
        if(users[i].id == user.id)
        {
          newUser = false;
          break;
        }
      }
      if(newUser)
      {
        APIDatabaseHelper.insertUser(user);
      }
      APIRequestHelper.instance.user = user;
    }

    print("Respuesta user: " + response.statusCode.toString());
    return null;
  }
  
  static Future<Vehicle?> getVehicle(String id) async
  {
    if(!instance.isConnected())
    {
      return null;
    }

    Client client = Client();

    final Response response = await client.get(Uri.parse("https://api.smartcar.com/v2.0/vehicles/$id"),
      headers: {
        'Authorization': 'Bearer ${APIRequestHelper.instance.accessToken!.value}'
      }
    );

    if(response.statusCode == 200)
    {
      var data = json.decode(response.body);
      return Vehicle(userID: APIRequestHelper.instance.user!.id, id: data['id'], make: data['make'], model: data['model'], year: data['year']);
    }

    print("Respuesta vehiculo $id: " + response.statusCode.toString());
    return null;
  }

  static Future<double?> getFuelRemaining(Vehicle vehicle) async
  {
    if(!instance.isConnected())
    {
      return null;
    }

    Client client = Client();

    final Response response = await client.get(Uri.parse("https://api.smartcar.com/v2.0/vehicles/${vehicle.id}/fuel" ),
      headers: {
        'Authorization': 'Bearer ${APIRequestHelper.instance.accessToken!.value}'
      }
    );

    if(response.statusCode == 200)
    {
      var data = json.decode(response.body);
      return data['percentRemaining'] * 100;
    };

    print("Respuesta combustible" + response.statusCode.toString());
    return null;
  }

  static Future<double?> getEVRemaing(Vehicle vehicle) async
  {
    if(!instance.isConnected())
    {
      return null;
    }

    Client client = Client();

    final Response response = await client.get(Uri.parse("https://api.smartcar.com/v2.0/vehicles/${vehicle.id}/battery" ),
      headers: {
        'Authorization': 'Bearer ${APIRequestHelper.instance.accessToken!.value}'
      }
    );

    if(response.statusCode == 200)
    {
      var data = json.decode(response.body);
      return data['percentRemaining'] * 100;
    };

    print("Respuesta bateria" + response.statusCode.toString());
    return null;
  }
}