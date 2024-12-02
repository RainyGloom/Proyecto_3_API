import 'package:flutter/material.dart';
import 'package:odometer_app/api_database_helper.dart';
import 'package:odometer_app/content/speed_entry.dart';
import 'package:odometer_app/content/vehicle.dart';

enum MeasurementUnit { kmh, mph }

class GlobalSettings {
  // Singleton para asegurar una única instancia global
  static final GlobalSettings _instance = GlobalSettings._internal();
  factory GlobalSettings() => _instance;
  GlobalSettings._internal();


  Color foreColor = Color.fromARGB(255, 232, 216, 201);
  Color secondColor = Color.fromARGB(255, 75, 96, 127);
  Color thirdColor = Color.fromARGB(255, 243, 112, 30);
  // Estado global de las configuraciones
  String _unit = 'km/h'; // Unidades de medida por defecto
  bool _isNightMode = false; // Modo nocturno por defecto
  double _brightness = 0.5; // Brillo por defecto (0.0 a 1.0)

  // Historial de velocidades
  late final List<SpeedEntry> _speedHistory;

  String get unit => _unit;
  set unit(String value) {
    _unit = value;
    debugPrint("Unidad de medida actualizada a: $_unit");
  }

  bool get isNightMode => _isNightMode;
  set isNightMode(bool value) {
    _isNightMode = value;
    debugPrint("Modo nocturno actualizado a: $_isNightMode");
  }

  double get brightness => _brightness;
  set brightness(double value) {
    _brightness = value.clamp(0.0, 1.0); 
    debugPrint("Brillo actualizado a: $_brightness");
  }

  List<SpeedEntry> get speedHistory => List.unmodifiable(_speedHistory);
  
  void addSpeed(Vehicle vehicle, double speed, DateTime dateTime) {
    SpeedEntry entry = SpeedEntry(vehicleID: vehicle.id, dateTime: dateTime, speed: speed);
    _speedHistory.add(entry);
    APIDatabaseHelper.insertSpeedEntry(entry);
    debugPrint("Velocidad registrada: $speed");
    print('DateTime: ${dateTime}');
  }

  // Velocidad mínima del historial
  double get minSpeed => _speedHistory.isEmpty
      ? 0
      : _speedHistory.reduce((a, b) => a.speed < b.speed ? a : b).speed;

  // Velocidad máxima del historial
  double get maxSpeed => _speedHistory.isEmpty
      ? 0
      : _speedHistory.reduce((a, b) => a.speed > b.speed ? a : b).speed;


  // Resetear el historial de velocidades (opcional)
  void clearSpeedHistory() {
    _speedHistory.clear();
    debugPrint("Historial de velocidades reiniciado");
  }

    /// Convierte velocidad según la unidad seleccionada
  double convertSpeed(double speed) {
    if (_unit.toLowerCase() == "mph") {
      return speed * 0.621371; // de KM/H a MPH
    }
    return speed;
  }

  Future<void> loadEntries() async
  {
    _speedHistory = await APIDatabaseHelper.getSpeedEntries();
  }
}
