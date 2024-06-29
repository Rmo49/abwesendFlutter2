import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:abwesend/model/globals.dart' as global;

import 'my_uri.dart';

class Config {

  static Map<String, dynamic>?  configMap;
  // die Keys in der Map
  static const String turnierBeginDatum = 'turnier.beginDatum';
  static const String turnierEndDatum = 'turnier.endDatum';
  static const String weekBeginZeit = 'week.beginZeit';
  static const String weekEndZeit = 'week.endZeit';
  static const String weekendBeginZeit = 'weekend.beginZeit';
  static const String weekendEndZeit = 'weekend.endZeit';
  static const String zeitStart = 'zeit.start';
  static const String zeitEnde = 'zeit.ende';
  static const String dayBeginZeit = 'day.beginZeit';
  static const String dayEndZeit = 'day.endZeit';
  static const String spielerListeMax = 'spieler.liste.max';



  /// Die Configuration von DB lesen, die Daten werden in json-format geliefert
  static Future<String> readConfig() async {
    String message = "";
    try {
      // var global;
      final response = await http.post(MyUri.getUri("/readConfig.php"), body: {
        "dbname": global.dbName,
        "dbuser": global.dbUser,
        "dbpass": global.dbPass,
      });
      if (response.statusCode == 200) {
        configMap = json.decode(response.body);
       _setGlobalData();
      } else {
        message = response.body;
      }
    } catch (e) {
      debugPrint ('Fehler in readConfig:  $e');
        message = 'in Config lesen, ist eine Internet-Verbindung vorhanden? \n $e';
      }
      return message;
    }

  /// Die Config-Daten setzen in global
  static String _setGlobalData() {
    if (configMap!.isEmpty) {
      return 'Config Daten nicht gelesen.';
    }
    global.startDatum = _parseDatum(turnierBeginDatum);
    global.endDatum = _parseDatum(turnierEndDatum);
    Duration diff = global.endDatum.difference(global.startDatum);
    // die Anzahl tage für die Anzeige
    global.arrayLenMax = diff.inDays + 1;
    global.arrayLenMax < 0
        ? global.arrayLenMax = -global.arrayLenMax
        : global.arrayLenMax = global.arrayLenMax;
    if (global.arrayLenMax > global.arrayLenMaxAbsolut) {
      global.arrayLenMax = global.arrayLenMaxAbsolut;
    }

    global.zeitWeekBegin =  _parseDouble(weekBeginZeit);
    global.zeitWeekEnd = _parseDouble(weekEndZeit);
    global.zeitWeekendBegin = _parseDouble(weekendBeginZeit);
    global.zeitWeekendEnd = _parseDouble(weekendEndZeit);
    // die Zeiten pro Tag
    global.zeitStart = _parseZeiten(zeitStart);
    global.zeitEnde = _parseZeiten(zeitEnde);
    global.spielerListMax = _parseInt(spielerListeMax);
    return "";
  }

  /// Den Eintrag in Map prüfen, wenn nicht vorhanden, wird angelegt
  static DateTime _parseDatum(String key) {
    DateTime dt = global.startDatum;
    if (configMap!.containsKey(key)) {
       dt = global.dateFormDb.parse(configMap![key]);
    }
    else {
      // wenn key noch nicht in configMap
      configMap!.addEntries([MapEntry(key, dt.toString())]);
    }
    return dt;
  }

  /// Den Array füllen mit den Zeiten
  static List<int> _parseZeiten(String key) {
    List<String> dayListStr;
    List<int> dayList = [];
    if (configMap!.containsKey(key)) {
      // TODO hier Liste übertragen
      String dayStr = configMap![key];
      dayListStr = dayStr.split(";");
      for (int i = 0; i < global.arrayLenMax; i++) {
        dayList.add(int.parse(dayListStr[i]));
      }
    }
    else {
      // wenn key noch nicht in configMap
      configMap!.addEntries([MapEntry(key, ";")]);
    }
    return dayList;
  }

  /// Den Eintrag in Map prüfen, wenn nicht vorhanden, wird angelegt
  static double _parseDouble(String key) {
    double wert = 1;
    if (configMap!.containsKey(key)) {
      wert = double.parse(configMap![key]);
    }
    else {
      configMap!.addEntries([MapEntry(key, '1')]);
    }
    return wert;
  }

  /// Den Eintrag in Map prüfen, wenn nicht vorhanden, wird angelegt
  static int _parseInt(String key) {
    int wert = 1;
    if (configMap!.containsKey(key)) {
      wert = int.parse(configMap![key]);
    }
    else {
      configMap!.addEntries([MapEntry(key, '1')]);
    }
    return wert;
  }


  static updateConfig(String key, String newValue) {
    if (key.isNotEmpty && newValue.isNotEmpty) {
      configMap!.update(key, (value) => newValue);
    }
  }

  /// Die Configuration in die DB speichern
  /// die Daten werden in json-format geliefert
  static Future<String> saveConfig(String key, String value) async {
    String? message = "";
    try {
      final response = await http.post(MyUri.getUri("/saveConfig.php"), body: {
        "dbname": global.dbName,
        "dbuser": global.dbUser,
        "dbpass": global.dbPass,
        "userName": global.userName,
        "configToken": key,
        "configWert": value
      });
      if (response.statusCode == 200) {
          message = response.reasonPhrase as String;
          // message = "OK gespeichert";
      } else {
        message = "Du darft nicht ändern";
      }
    } catch (e) {
      debugPrint('Fehler in saveConfig:  $e');
      message = 'Kann Config nicht speichen. \n $e';
    }
    return message;
  }
}