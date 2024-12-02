import 'package:flutter/material.dart';
import 'package:odometer_app/api_request_helper.dart';
import 'package:odometer_app/global_settings.dart';
import 'package:odometer_app/pages/main_page.dart';
import 'package:flutter_smartcar_auth/flutter_smartcar_auth.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  APIRequestHelper(
    clientId: "1ce2d74b-1016-454a-baa8-f8a1592bc456", 
    clientSecret: "7222e03d-0437-437d-95ea-65ba26f09160", 
    uri: "sc1ce2d74b-1016-454a-baa8-f8a1592bc456://speedo"
  );
  await Smartcar.setup(
    configuration: SmartcarConfig(
      clientId: APIRequestHelper.instance.clientId,
      redirectUri: APIRequestHelper.instance.uri,
      scopes: [
        SmartcarPermission.readOdometer, 
        SmartcarPermission.readLocation, 
        SmartcarPermission.readVehicleInfo, 
        SmartcarPermission.readSpeedometer,
      ],
      mode: SmartcarMode.test,
    ),
  );
  await GlobalSettings().loadEntries();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: MainPage(),
      ),
    );
  }
}
