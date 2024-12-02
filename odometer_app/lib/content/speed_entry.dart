class SpeedEntry {
  const SpeedEntry({required this.vehicleID, required this.dateTime, required this.speed});

  final String vehicleID;
  final DateTime dateTime;
  final double speed;

  Map<String, Object> toMap()
  {
    return
    {
      'vehicleID': vehicleID,
      'dateTime': dateTime.toString(),
      'speed': speed,
    };
  }
  
}