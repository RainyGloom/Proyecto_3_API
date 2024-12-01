import 'package:flutter/material.dart';
import 'package:flutter_smartcar_auth/flutter_smartcar_auth.dart';
import 'package:odometer_app/api_request_helper.dart';
import 'package:odometer_app/pages/home_page.dart';
import 'dart:convert';
import 'package:http/http.dart';


class SmartcarAuthMenu extends StatefulWidget {
  const SmartcarAuthMenu({super.key});

  @override
  State<SmartcarAuthMenu> createState() => _SmartcarAuthMenuState();
}

class _SmartcarAuthMenuState extends State<SmartcarAuthMenu> {
  
  static Future<void> _getAccessToken() async
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
  
  @override
  void initState() {
    super.initState();

    Smartcar.onSmartcarResponse.listen(_handleSmartcarResponse);
  }

  String buttonName = "No load";

  void _handleSmartcarResponse(SmartcarAuthResponse response) {
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
                do
                {
                  await _getAccessToken();
                  if(APIRequestHelper.instance.accessToken != null)
                  {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                  }
                }while(APIRequestHelper.instance.accessToken == null);
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