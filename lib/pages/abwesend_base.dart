import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abwesend/model/globals.dart' as global;
import 'package:abwesend/model/spieler.dart';

/// Basis-Funktionen für die Anzeige
class AbwesendBase {
  static final DateFormat dateFormList = DateFormat('d.M.');

  static List<TableCell> getCellsDatum(BuildContext context, String title,
      DateTime? startDatum, int anzahlTage) {
    // Die Zeile mit dem Datum
    DateTime? datum = startDatum;
    List<TableCell> list = [];
    list.add(TableCell(child: Text(title)));

    for (int i = 0; i < anzahlTage; i++) {
      list.add(
        TableCell(
            child: Container(
              color: isWeekend(i) ? Colors.grey : Colors.white,
              child:
              Text(dateFormList.format(datum!),
                  style: Theme
                      .of(context)
                      .textTheme
                      .labelLarge),
            )),
      );
      datum = datum.add(const Duration(days: 1));
    }
    return list;
  }

  /// Ist die Position im Array ein Weekend?
  static bool isWeekend(int pos) {
    DateTime? datum = global.startDatum;
    datum = global.startDatum.add(Duration(days: pos));
    return (datum.weekday >= 6);
  }

  /// Abwesenheitszeile
  static List<TableCell> getCellsAbwesend(BuildContext context, String header,
      List<String>? abwesendList, int von, int bis) {
    List<TableCell> list = [];
    list.add(TableCell(child: Text(header)));

    for (int i = von; i < bis; i++) {
      if (i < abwesendList!.length) {
        list.add(
          TableCell(child:
          Text(abwesendList[i],
              style: Theme
                  .of(context)
                  .textTheme
                  .labelLarge),
          ),
        );
      }
    }
    return list;
  }

  /// Abwesenheiten grafisch
  static List<TableCell> getCellsGrafik(Spieler? spieler, List? abwesendList,
      int von, int bis) {
    List<TableCell> list = [];
    // dazufügen wegen header
    if (von < 0) {
      list.add(const TableCell(child: Text("Grafik")));
      von++;
    }

    for (int dayNr = von; dayNr < bis; dayNr++) {
      if (dayNr < abwesendList!.length) {
        String abwTag = abwesendList[dayNr];
        abwTag = abwTag.trim();
        double abwStart = getPosStart(abwTag, dayNr);
        double abwEnd = getPosEnd(abwTag, dayNr, abwStart);
        // matches, wenn von diesem Tag
        List<MatchDisplay> matchDisplayList = getMatches(spieler!, dayNr);
        MyPainter painter = MyPainter(abwStart, abwEnd, matchDisplayList);
        list.add(
          TableCell(
              child: SizedBox(
                height: 20.0,
                child: CustomPaint(painter: painter),
              )),
        );
      }
    }
    return list;
  }

  /// Gibt für einen Tag in der Liste die Matches zurück
  static List<MatchDisplay> getMatches(Spieler spieler, int dayNr) {
    List<MatchDisplay> matchDispalyList = [];
    for (int i = 0; i < spieler.matches.length; i++) {
      MatchDisplay matchDisplay;
      // wenn Spiele an diesem Tag
      if (spieler.matches
          .elementAt(i)
          .day == dayNr) {
        double pos = getPosTime(spieler.matches[i].time!, dayNr);
        if (pos >= 0.8) {
          pos = 0.8;
        }
        matchDisplay = MatchDisplay(pos, spieler.matches[i].type);
        matchDispalyList.add(matchDisplay);
      }
    }
    return matchDispalyList;
  }


  /// Berechnet die Start Position, 0..1 innerhalb der Zeitspannen
  /// von Start-Zeit und Ende
  static double getPosStart(String abwTag, int dayNr) {
    if (abwTag.isEmpty) {
      // nichts zeichnen
      return 1;
    }
    // wenn am Anfang fehlt
    if (abwTag.startsWith('-') || (abwTag.compareTo('0') == 0)) {
      return 0;
    }
    // wenn "18-", dann ist Anfang > 0
    int posEnd = abwTag.indexOf('-');
    if (posEnd > 0) {
      String zeit = abwTag.substring(0, posEnd);
      if (zeit.isNotEmpty) {
        return getPosTime(zeit, dayNr);
      }
    } else {
      // kein '-' gefunden
      return 0;
    }
    return 1.0;
  }

  /// Berechnet die End Position, von 0..1 innerhalb der Zeitspannen
  /// von Start-Zeit und Ende
  static double getPosEnd(String abwTag, int dayNr, double posStart) {
    if (posStart >= 1) {
      // nichts zeichnen
      return 1.0;
    }
    if (abwTag.compareTo('0') == 0) {
      return 1.0;
    }
    if (abwTag.startsWith('-')) {
      String zeit = abwTag.substring(abwTag.indexOf('-') + 1, abwTag.length);
      if (zeit.isNotEmpty) {
        return getPosTime(zeit, dayNr);
      }
    }
    return 1.0;
  }

  /// Die Position von 0..1 innerhalb der Zeitspannen
  /// wenn 1 dann ausserhalb der Zeitspanne
  static double getPosTime(String time, int dayNr) {
    // wenn Zeit "18:30", dann Minuten weglassen
    int index = time.indexOf(RegExp('[:.,]'));
    if (index > 0) {
      time = time.substring(0, index);
    }

    int zeit = 0;
    double pos = 1.0;
    try {
      zeit = int.parse(time);
    }
    on FormatException {
      // nix machen
    }
    // die Funktion muss wissen welcher Tag es betrifft
    pos = (zeit - global.zeitStart[dayNr]) /
        (global.zeitEnde[dayNr] - global.zeitStart[dayNr]);
    if (pos < 0) {
      pos = 0.0;
    }
    if (pos > 1) {
      pos = 1.0;
    }
    return pos;
  }
}


//-------------------------
/// Der Painter für die grafische Dartstellung
class MyPainter extends CustomPainter {
  final double posStart;
  final double posEnd;
  final List<MatchDisplay> matchDisplayList;
  // Konstruktor
  MyPainter(this.posStart, this.posEnd, this.matchDisplayList);

  final painterAbw = Paint()..color = Colors.deepOrangeAccent;
  final painterEinzel = Paint()..color = Colors.blue[700]!;
  final painterDoppel = Paint()..color = Colors.green[700]!;

  @override
  void paint(Canvas canvas, Size size) {
    if (posStart < 1) {
      double left = posStart * size.width;
      double width = (posEnd * size.width) - left;
      canvas.drawRect(Rect.fromLTWH(left, 0.0, width, size.height), painterAbw);
    }
    if (matchDisplayList.isNotEmpty) {
      for (var match in matchDisplayList) {
        if (match.pos < 1) {
          double left = match.pos * size.width;
          if (match.type!.contains('E')) {
            canvas.drawRect(
                Rect.fromLTWH(left, 0.0, 8, size.height), painterEinzel);
          } else {
            canvas.drawRect(
                Rect.fromLTWH(left, 0.0, 8, size.height), painterDoppel);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
