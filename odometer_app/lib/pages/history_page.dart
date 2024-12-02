import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:odometer_app/content/speed_entry.dart';
import 'package:odometer_app/global_settings.dart';
import 'package:intl/date_symbol_data_local.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<SpeedEntry> speedHistory = GlobalSettings().speedHistory;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
            "Historial de Velocidades",
            style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: GlobalSettings().foreColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: speedHistory.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: SizedBox(
                      height: 50,
                      child: Card(
                        color: GlobalSettings().secondColor,
                        child: Center(
                          child: Text(
                            "${DateFormat('dd/MM/yyyy HH:mm').format(speedHistory[index].dateTime)} Velocidad: ${GlobalSettings().convertSpeed(speedHistory[index].speed).toStringAsFixed(1)} ${GlobalSettings().unit}",
                            style: TextStyle(color: GlobalSettings().foreColor),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(),
              color: GlobalSettings().foreColor,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Text(
                      "Velocidad mínima: ${GlobalSettings().minSpeed.toStringAsFixed(1)} ${GlobalSettings().unit}",
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                    Text(
                      "Velocidad máxima: ${GlobalSettings().maxSpeed.toStringAsFixed(1)} ${GlobalSettings().unit}",
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
