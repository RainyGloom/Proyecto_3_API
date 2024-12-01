import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_smartcar_auth/flutter_smartcar_auth.dart';
import 'package:http/http.dart';
import 'package:odometer_app/api_request_helper.dart';
import 'package:odometer_app/content/vehicle.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as paths;
import 'dart:convert';
import 'dart:async';

class HomePage extends StatefulWidget
{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage>
{
  _HomePageState();
  double result = 0;
  double? _distance;
  bool _init = false;
  double _secondsOnFail = 0;
  bool _requestStarted = false;

  Future<void> _setDistance(Timer timer) async
  {
    if(_requestStarted)
    {
      _secondsOnFail++;
      return;
    }
    List<Vehicle> vehicles = APIRequestHelper.instance.vehicles;
    if(vehicles.isEmpty)
    {
      _secondsOnFail = 0;
      _distance = null;
      return;
    }
    if(_distance == null)
    {
      _secondsOnFail = 0;
      _requestStarted = true;
      _distance = await APIRequestHelper.getOdometerDistance(vehicles[0].id);
    }
    else
    {
      double? next = await APIRequestHelper.getOdometerDistance(vehicles[0].id);
      if(next != null)
      {
        result = (next - _distance!) / 10 * (1 + _secondsOnFail);
        _secondsOnFail = 0;
        _distance = next;
        print("Funciona");
      }
      else
      {
        _secondsOnFail++;
      }
    }
    _requestStarted = false;
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    //return FutureBuilder<Scaffold>(future: () async => { return get()}, builder: builder)
    return Scaffold(
      body: FutureBuilder(
        future: APIRequestHelper.loadVehicles(),
        builder: (context, snapshot)
        {
          if(snapshot.connectionState == ConnectionState.done)
          {
            if(!_init)
            {
              Timer.periodic(Duration(seconds: 10), _setDistance);
              _init = true;
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${snapshot.error} occurred',
                  style: TextStyle(fontSize: 18),
                ),
              );
            }
              return Center(
                child: Text(result.toString())
              );
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      )
    );
  }
}