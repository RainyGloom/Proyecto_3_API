import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:odometer_app/global_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _selectedUnit; // Unidades de medida locales
  late bool _isNightMode; // Modo nocturno local
  late double _brightness; // Brillo local

  @override
  void initState() {
    super.initState();
    // Inicializa valores locales con los valores del servicio global
    _selectedUnit = GlobalSettings().unit.toString();
    _isNightMode = GlobalSettings().isNightMode;
    _brightness = GlobalSettings().brightness;

    // Establece brillo inicial de la pantalla
    _updateScreenBrightness(_brightness);
  }

  /// Ajustar brillo 
  Future<void> _updateScreenBrightness(double value) async {
    try {
      await ScreenBrightness().setScreenBrightness(value);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al ajustar el brillo: $e')),
      );
    }
  }

  /// Guardar cambios en el servicio global
  void _saveChanges() {
    setState(() {
      GlobalSettings().unit = _selectedUnit;
      GlobalSettings().isNightMode = _isNightMode;
      GlobalSettings().brightness = _brightness;
    });

    // Mensaje de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cambios guardados'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: GlobalSettings().foreColor,
        elevation: 0,
        title: const Text('Ajustes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
           
            Text(
              "Unidades de medida",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GlobalSettings().foreColor,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<String>(
                  value: 'km/h',
                  groupValue: _selectedUnit,
                  onChanged: (value) {
                    setState(() {
                      _selectedUnit = value!;
                    });
                  },
                  activeColor: GlobalSettings().thirdColor,
                ),
                Text(
                  'Kilómetros por hora (km/h)',
                  style: TextStyle(color: GlobalSettings().foreColor, fontSize: 18),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<String>(
                  value: 'mph',
                  groupValue: _selectedUnit,
                  onChanged: (value) {
                    setState(() {
                      _selectedUnit = value!;
                    });
                  },
                  activeColor: GlobalSettings().thirdColor,
                ),
                Text(
                  'Millas por hora (mph)',
                  style: TextStyle(color: GlobalSettings().foreColor, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 32),
     
            Text(
              "Modo nocturno",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GlobalSettings().foreColor,
              ),
            ),
            const SizedBox(height: 16),
   
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Activar modo nocturno",
                  style: TextStyle(color: GlobalSettings().foreColor, fontSize: 18),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: _isNightMode,
                  onChanged: (value) {
                    setState(() {
                      _isNightMode = value;
                    });
                  },
                  activeColor: GlobalSettings().thirdColor,
                ),
              ],
            ),
            const SizedBox(height: 32),
       
            Text(
              "Brillo pantalla",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GlobalSettings().foreColor,
              ),
            ),
            const SizedBox(height: 16),
      
            Slider(
              value: _brightness,
              onChanged: (value) {
                setState(() {
                  _brightness = value;
                  _updateScreenBrightness(value);
                });
              },
              min: 0.0,
              max: 1.0,
              activeColor: GlobalSettings().thirdColor,
              inactiveColor: GlobalSettings().secondColor,
            ),
            const SizedBox(height: 32),
    
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalSettings().foreColor, 
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Guardar Cambios',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
