import 'package:flutter/material.dart';
import 'dart:async';
import 'package:odometer_app/api_request_helper.dart';
import 'package:odometer_app/pages/history_page.dart';
import 'package:odometer_app/pages/profile_page.dart';
import 'package:odometer_app/pages/settings_page.dart';
import 'package:odometer_app/global_settings.dart';
import 'package:flutter_smartcar_auth/flutter_smartcar_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  double? _lastDistance;
  double _currentSpeed = 0;
  double _currentFuelPercent = 0;
  double _minSpeed = 0;
  double _maxSpeed = 0;
  DateTime? _lastTime;
  String _connect = "Conectar vehículo";
  MeasurementUnit _unit = MeasurementUnit.kmh;
  Timer? _timer;
  FlutterRingtonePlayer? _player;
  Widget? _dialog;

    @override
  void initState() 
  {
    super.initState();
    _loadSettings(); 
    Smartcar.onSmartcarResponse.listen(_handleSmartcarResponse);
    Timer.periodic(Duration(seconds: 1),
    (timer) async
    {
      if(GlobalSettings().convertSpeed(_currentSpeed) > GlobalSettings().convertSpeed(130))
      {
        if(_player == null)
        {
          _player = FlutterRingtonePlayer();
          FlutterRingtonePlayer().play(
            android: AndroidSounds.alarm,
            ios: IosSounds.electronic,
            looping: true,
          );
          _dialog = await showAlertDialog(context);
        }
      }
      else if(_player != null)
      {
        if(_dialog != null)
        {
          Navigator.pop(context);
          _dialog = null;
        }
        _player!.stop();
        _player = null;
      }
    });
  }

  Future<Widget> showAlertDialog(BuildContext context) async{
    AlertDialog alert = AlertDialog(
      backgroundColor: GlobalSettings().foreColor,
      title: const Text("Exceso de velocidad", style: TextStyle(color: Colors.black),),
      content: const Text('Reduzca la velocidad', style: TextStyle(color: Colors.black),),
    );

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );

    return alert;
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
    Timer.periodic(const Duration(seconds: 5), 
      (timer) async
      {
        double? percent = await APIRequestHelper.getFuelRemaining(APIRequestHelper.instance.vehicles[0]);
        if(percent != null)
        {
          _currentFuelPercent = percent;
        }
        else
        {
          percent = await APIRequestHelper.getEVRemaing(APIRequestHelper.instance.vehicles[0]);
          _currentFuelPercent = percent ?? _currentFuelPercent;
        }
      }
    );
    _timer = Timer.periodic(const Duration(seconds: 5), 
      (timer) async {
        if (APIRequestHelper.instance.vehicles.isNotEmpty) {
          // VELOCIDAAD
          double? distance = await APIRequestHelper.getOdometer(APIRequestHelper.instance.vehicles.first);
          if(_lastDistance != null)
          {
            final deltaTime = DateTime.now().difference(_lastTime!);
            if(distance != null)
            {
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
            }
            else
            {
              if(deltaTime.inMinutes >= 2.5)
              {
                setState(() {
                  _lastTime = DateTime.now();
                  _currentSpeed = GlobalSettings().convertSpeed(0); // conversión unidad medida
                });
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
      }
    );
  }

  void _showDevelopersInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: GlobalSettings().foreColor,
          title: const Text('Información de los desarrolladores', style: TextStyle(color: Colors.black),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/images/leandro.png'),
                    radius: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Leandro Carvajal',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        Text('Edad: 22 años', style: TextStyle(color: Colors.black)),
                        Text('Ramo: Programación para dispositivos móviles', style: TextStyle(color: Colors.black)),
                        Text('Universidad: Universidad de Talca', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/images/maria_paz.png'),
                    radius: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'María Paz Alarcón Fica',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        Text('Edad: 21 años'),
                        Text('Ramo: Programación para dispositivos móviles', style: TextStyle(color: Colors.black)),
                        Text('Universidad: Universidad de Talca', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ],
        );
      },
    );
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
        title: Padding
        ( 
          padding: EdgeInsets.only(right: 70),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: Image.asset('assets/icons/drivex_icon.png'),
              ),
              const Text(
                'DriveX',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        backgroundColor: GlobalSettings().foreColor,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.black),
          onPressed: _showDevelopersInfo,
        ),
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
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                    '${_currentFuelPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: GlobalSettings().foreColor,
                    ),
                  ),
                  Text(
                    "Fuel/Battery",
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
                        Icons.local_gas_station,
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
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              ),
            ).then((_) {
              _loadSettings();
            });
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
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
