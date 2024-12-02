import 'package:flutter/material.dart';
import 'package:odometer_app/api_request_helper.dart';
import 'package:odometer_app/content/user.dart';
import 'package:odometer_app/content/vehicle.dart';
import 'package:odometer_app/global_settings.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _userData; // Datos usuario
  Vehicle? _vehicleData; // Datos vehículo
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      // Obtener datos del usuario
      await APIRequestHelper.loadUser();
      User? userData = APIRequestHelper.instance.user;

      // Obtener datos del vehículo
      await APIRequestHelper.loadVehicles();
      List<Vehicle> vehicles = APIRequestHelper.instance.vehicles;

      setState(() {
        _userData = userData;
        if(vehicles.isNotEmpty)
        {
          _vehicleData = vehicles[0];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }
  
  Widget _createView(int index)
  {
    Vehicle vehicle = APIRequestHelper.instance.vehicles[index];
    return Container(
      width: double.infinity,
      child: Card(
        color: GlobalSettings().secondColor,
        child: Column(
          children: 
          [
            Text(
              'Marca: ${vehicle.make}',
              style: TextStyle(color: GlobalSettings().foreColor),
            ),
            Text(
              'Modelo: ${vehicle.model}',
              style: TextStyle(color: GlobalSettings().foreColor),
            ),
            Text(
              'Año: ${vehicle.year}',
              style: TextStyle(color: GlobalSettings().foreColor),
            ),
          ]
        ),
      )
    );
  }
  @override
  Widget build(BuildContext context) {
    List<Widget> cards =
    [
      Center(
        child: Text(
          'Vehículos asociados a la cuenta',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: GlobalSettings().foreColor,
          ),
        ),
      ),
      const SizedBox(height: 10),
    ];
    for(int i = 0; i < APIRequestHelper.instance.vehicles.length; i++)
    {
      cards.add(_createView(i));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: GlobalSettings().foreColor,
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cards,
              ),
            ),
    );
  }
}
