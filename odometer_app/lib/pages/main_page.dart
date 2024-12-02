import 'package:flutter/material.dart';
import 'dart:async';
import 'package:odometer_app/api_request_helper.dart';
import 'package:odometer_app/pages/history_page.dart';
import 'package:odometer_app/pages/profile_page.dart';
import 'package:odometer_app/pages/settings_page.dart';
import 'package:odometer_app/global_settings.dart';
import 'package:flutter_smartcar_auth/flutter_smartcar_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  double? _lastDistance;
  double _currentSpeed = 0;
  double _currentRPM = 0;
  double _minSpeed = 0;
  double _maxSpeed = 0;
  DateTime? _lastTime;
  String _connect = "Conectar vehículo";
  MeasurementUnit _unit = MeasurementUnit.kmh; // Unidad seleccionada (por defecto KM/H)
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadSettings(); 
    Smartcar.onSmartcarResponse.listen(_handleSmartcarResponse);
  }

  Future<void> _handleSmartcarResponse(SmartcarAuthResponse response) async{
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    switch (response) {
      case SmartcarAuthSuccess success:
        APIRequestHelper.instance.authCode = success.code;
        scaffoldMessenger.showMaterialBanner(
          MaterialBanner(
            backgroundColor: GlobalSettings().secondColor,
            content: Center(
              child: Text(
                'Conexión exitosa',
                style: TextStyle(
                  color: GlobalSettings().foreColor,
                ),
              ),
            ),
            actions: const [SizedBox.shrink()],
          ),
        
        );

        do
        {
          await APIRequestHelper.getAccessToken();
        }while(APIRequestHelper.instance.accessToken == null);
        await APIRequestHelper.loadUser();
        await APIRequestHelper.loadVehicles();
        _startRealTimeUpdates();
        setState(() {
          _connect = APIRequestHelper.instance.vehicles[0].toString();
        });
        break;
      case SmartcarAuthFailure failure:
        scaffoldMessenger.showMaterialBanner(
          MaterialBanner(
            backgroundColor: GlobalSettings().thirdColor,
            content: Center(
              child: Text(
                'error: ${failure.description}',
                style: TextStyle(
                  color: GlobalSettings().foreColor,
                ),
              ),
            ),
            actions: const [SizedBox.shrink()],
          ),
        );
        break;
    }

    Future.delayed(
      const Duration(
        seconds: 3,
      ),
    ).then((_) => scaffoldMessenger.hideCurrentMaterialBanner());
  }

  void _loadSettings() {
    setState(() {
      // unidad seleccionada desde configuración global
      _unit = GlobalSettings().unit == 'km/h'
          ? MeasurementUnit.kmh
          : MeasurementUnit.mph;
    });
  }

  Future<void> _connectVehicle() async
  {
    if(APIRequestHelper.instance.isConnected())
    {
      return;
    }

    final List<ConnectivityResult> result = await Connectivity().checkConnectivity();

    if(result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile))
    {
      await Smartcar.launchAuthFlow();
    }
    else
    {
      ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            backgroundColor: GlobalSettings().thirdColor,
            content: Center(
              child: Text(
                'No se encuentra conectado a la red',
                style: TextStyle(
                  color: GlobalSettings().foreColor,
                ),
              ),
            ),
            actions: const [SizedBox.shrink()],
          ),
        
      );
      Future.delayed(
        const Duration(
          seconds: 3,
        ),
      ).then((_) => ScaffoldMessenger.of(context).hideCurrentMaterialBanner());
    }
  }

  void _startRealTimeUpdates() {
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (APIRequestHelper.instance.vehicles.isNotEmpty) {
        // VELOCIDAAD
        double? distance = await APIRequestHelper.getOdometer(APIRequestHelper.instance.vehicles.first);
        if(_lastDistance != null)
        {
          if(distance != null)
          {
            final deltaTime = DateTime.now().difference(_lastTime!);
            if(distance != _lastDistance)
            {
              double speed = (distance - _lastDistance!) / (deltaTime.inMilliseconds) * 3600000;
              if(speed >= 0)
              {
                setState((){
                    _lastTime = DateTime.now();
                    _currentSpeed = speed; // registrar velocidad en el historial
                    _minSpeed = GlobalSettings().minSpeed;
                    _maxSpeed = GlobalSettings().maxSpeed;
                    GlobalSettings().addSpeed(APIRequestHelper.instance.vehicles[0], _currentSpeed, _lastTime!);
                    _lastDistance = distance;
                });
              }
            }
            else
            {
              if(deltaTime.inMinutes >= 5)
              {
                setState(() {
                  _lastTime = DateTime.now();
                  _currentSpeed = GlobalSettings().convertSpeed(0); // conversión unidad medida
                });
              }
            }
          }
        }
        else
        {
          _lastDistance = distance;
          _lastTime = DateTime.now();
        }

        // RPM
        /*double? rpm = await APIRequestHelper.getVehicleRPM(vehicleId);
        if (rpm != null) {
          setState(() {
            _currentRPM = rpm;
          });
        }*/
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('DRIVEX', style: TextStyle(color: Colors.black)),
        backgroundColor: GlobalSettings().foreColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            color: GlobalSettings().foreColor, 
            child: TextButton(
              onPressed: _connectVehicle, 
              child: Text(
                _connect,
                style: TextStyle(color: Colors.black),
              )
            )
          ),
          Text(''),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: (GlobalSettings().convertSpeed(_currentSpeed) / GlobalSettings().convertSpeed(240)).clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: GlobalSettings().secondColor,
                    valueColor: AlwaysStoppedAnimation(GlobalSettings().thirdColor),
                  ),
                ),
                Text(
                  GlobalSettings().convertSpeed(_currentSpeed).toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: GlobalSettings().foreColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    GlobalSettings().convertSpeed(_currentSpeed).toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: GlobalSettings().foreColor,
                    ),
                  ),
                  Text(
                    _unit == MeasurementUnit.kmh ? "KM/H" : "MPH",
                    style: TextStyle(
                      fontSize: 16,
                      color: GlobalSettings().foreColor,
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: GlobalSettings().foreColor, width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.speed,
                        size: 40,
                        color: GlobalSettings().foreColor,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    _currentRPM.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: GlobalSettings().foreColor,
                    ),
                  ),
                  Text(
                    "RPM",
                    style: TextStyle(
                      fontSize: 16,
                      color: GlobalSettings().foreColor,
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: GlobalSettings().foreColor, width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.rotate_right,
                        size: 40,
                        color: GlobalSettings().foreColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: GlobalSettings().foreColor,
        unselectedItemColor: GlobalSettings().foreColor,
        onTap: (index) {
          if (index == 0) 
          {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage(),),
            ).then((_) 
            {
              _loadSettings(); // Recargar configuración al volver
            });
          }else if (index == 1)
          {
            Navigator.push(context, MaterialPageRoute(builder: (context)=> const HistoryPage()));
          }else if (index == 2)
          {
            Navigator.push(context, MaterialPageRoute(builder: (context)=> const ProfilePage()));
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
