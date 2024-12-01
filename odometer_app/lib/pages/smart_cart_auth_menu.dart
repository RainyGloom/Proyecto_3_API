import 'package:flutter/material.dart';
import 'package:flutter_smartcar_auth/flutter_smartcar_auth.dart';
import 'package:odometer_app/api_database_helper.dart';
import 'package:odometer_app/api_request_helper.dart';
import 'package:odometer_app/content/user.dart';
import 'package:odometer_app/pages/home_page.dart';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:odometer_app/pages/vehicle_collection_page.dart';


class SmartcarAuthMenu extends StatefulWidget {
  const SmartcarAuthMenu({super.key});

  @override
  State<SmartcarAuthMenu> createState() => _SmartcarAuthMenuState();
}

class _SmartcarAuthMenuState extends State<SmartcarAuthMenu> {
  
  @override
  void initState() {
    super.initState();

    Smartcar.onSmartcarResponse.listen(_handleSmartcarResponse);
  }

  String buttonName = "No load";

  Future<void> _handleSmartcarResponse(SmartcarAuthResponse response) async{
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    switch (response) {
      case SmartcarAuthSuccess success:
        APIRequestHelper.instance.authCode = success.code;
        scaffoldMessenger.showMaterialBanner(
          MaterialBanner(
            backgroundColor: Colors.green,
            content: Text(
              'code: ${success.code}',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            actions: const [SizedBox.shrink()],
          ),
        
        );
        do
        {
          await APIRequestHelper.getAccessToken();
          if(APIRequestHelper.instance.accessToken != null)
          {
            do
            {
              await APIRequestHelper.getUser();
              if(APIRequestHelper.instance.user != null)
              {
                Navigator.push(context, MaterialPageRoute(builder: (context) => VehicleCollectionPage()));
              }
            }while(APIRequestHelper.instance.user == null);
          }
        }while(APIRequestHelper.instance.accessToken == null);
        break;
      case SmartcarAuthFailure failure:
        scaffoldMessenger.showMaterialBanner(
          MaterialBanner(
            backgroundColor: Colors.redAccent,
            content: Text(
              'error: ${failure.description}',
              style: const TextStyle(
                color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Smartcar Auth'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MaterialButton(
              onPressed: () async {
                await Smartcar.launchAuthFlow();

              },
              child: const Text("Launch Auth Flow"),
            ),
            MaterialButton(
              onPressed: () async {
                await Smartcar.launchAuthFlow(
                  authUrlBuilder: const AuthUrlBuilder(
                    flags: [
                      'tesla_auth:true',
                    ],
                    singleSelect: true,
                  ),
                );
              },
              child: const Text("Launch Auth Flow with Tesla Flag"),
            ),
          ],
        ),
      ),
    );
  }
}