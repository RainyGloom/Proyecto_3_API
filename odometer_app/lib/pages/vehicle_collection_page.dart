import 'package:flutter/material.dart';
import 'package:odometer_app/api_request_helper.dart';
import 'package:odometer_app/content/vehicle.dart';
import 'dart:async';

class VehicleCollectionPage extends StatefulWidget
{
  const VehicleCollectionPage({super.key});

  @override
  State<VehicleCollectionPage> createState() => _VehicleCollectionPageState();
}


class _VehicleCollectionPageState extends State<VehicleCollectionPage>
{
  _VehicleCollectionPageState();
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
      _distance = await APIRequestHelper.getOdometer(vehicles[0]);
    }
    else
    {
      double? next = await APIRequestHelper.getOdometer(vehicles[0]);
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
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${snapshot.error} occurred',
                  style: TextStyle(fontSize: 18),
                ),
              );
            }
            return Center(
              child: ListView.builder(
                itemCount: APIRequestHelper.instance.vehicles.length,
                itemBuilder: (context, index)
                {
                  return Card(
                    child: TextButton(
                      onPressed: () => {},
                      child: Text('${index + 1}. ${APIRequestHelper.instance.vehicles[index].make}')
                    ),
                  );
                }
              ),
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