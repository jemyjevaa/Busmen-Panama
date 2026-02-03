import 'package:flutter/material.dart';

class SchedulesViewModel extends ChangeNotifier {
  final List<Map<String, String>> _schedules = [
    {
      "route": "Ruta A - Centro",
      "departure": "06:00 AM",
      "arrival": "07:30 AM",
      "status": "A tiempo"
    },
    {
      "route": "Ruta B - Norte",
      "departure": "08:15 AM",
      "arrival": "09:45 AM",
      "status": "Retrasado"
    },
    {
      "route": "Ruta C - Sur",
      "departure": "04:00 PM",
      "arrival": "05:30 PM",
      "status": "A tiempo"
    },
  ];

  List<Map<String, String>> get schedules => _schedules;
}
