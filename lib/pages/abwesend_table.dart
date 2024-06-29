import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abwesend/model/spieler.dart';
import 'package:abwesend/pages/abwesend_base.dart';
import 'package:abwesend/model/globals.dart' as global;

/// zeigt die Tabelle Abwesend aller Spieler
class AbwesendTable extends StatelessWidget {

  final double sizeName = 65.0;
  final double sizeDay = 40.0;
//  double screenWidth = 500;
//  int displayDays = 10;
  final DateFormat dateFormList = DateFormat('d.M.');
  final BorderSide borderSide =
      const BorderSide(color: Colors.blueGrey, width: 1.0, style: BorderStyle.solid);

//  final Spieler spieler;
  final List<Spieler?>? spielerList;

  // Konstruktor
  AbwesendTable({super.key, this.spielerList});

  @override
  Widget build(BuildContext context) {
    // die Weite des screen bestimmen
    double screenWidth = MediaQuery.of(context).size.width;
    _calculateRows(screenWidth);
    return Column(
      children: _getTableList(context),
    );
  }

  /// die Anzahl Spalten berechnen
  void _calculateRows(double screenWidth) {
    double rows = (screenWidth - sizeName) / sizeDay;
    int displayDays = rows.toInt();
    displayDays--;
    if (displayDays > global.arrayLenMax) {
      displayDays = global.arrayLenMax;
    }
    global.arrayEnd = global.arrayStart + displayDays;
    Duration diff = global.endDatum.difference(global.startDatumAnzeigen);
    // wenn das Ende der Anzeige erreicht ist
    int daysMax = diff.inDays + 1;
    if (daysMax < displayDays) {
      global.arrayEnd = global.arrayStart + daysMax;
    }
  }

  /// alle Zeilen der Tabelle anzeigen, iteration über alle Spieler
  List<Table> _getTableList(BuildContext context) {
    List<Table> tableList = [];
    // die Zeile mit dem Datum
    tableList.add(_getTableDatum(context));

    // iteration über alle Spieler
    for (var element in spielerList!) {
      tableList.add(_getTableSpieler(context, element!));
    }
    return tableList;
  }

  /// Tabelle mit Datum
  Table _getTableDatum(BuildContext context) {
    List<TableRow> rowList = [];
    rowList.add(getRowDatum(context, '', global.startDatumAnzeigen));

    return Table(
      border: TableBorder(bottom: borderSide, verticalInside: borderSide),
      defaultColumnWidth: FixedColumnWidth(sizeDay),
      columnWidths: {
        0: FixedColumnWidth(sizeName),
      },
      children: rowList,
    );
  }

  /// Die erste Zeile mit Datum
  TableRow getRowDatum(BuildContext context, String header, DateTime? startDatum) {
    return TableRow(children: getCellsDatum(context, header, startDatum));
  }

  /// alle Zellen mit einem Datum
  /// header: Bezeichnung in der ersten Spalte
  List<TableCell> getCellsDatum(BuildContext context, String header, DateTime? startDatum) {
    // Die Zeile mit dem Datum
    DateTime? datum = startDatum;
    List<TableCell> list = [];
    list.add(TableCell(child: Text(header)));

    for (int i = global.arrayStart; i < global.arrayEnd; i++) {
      list.add(
        TableCell(
            child: Container(
          color: isWeekend(i) ? Colors.lightBlueAccent : Colors.white,
          child: Text(dateFormList.format(datum!),
              style: Theme.of(context).textTheme.labelLarge),
        )),
      );
      datum = datum.add(const Duration(days: 1));
    }
    return list;
  }

  /// Die Tabelle eines Spielers
  Table _getTableSpieler(BuildContext context, Spieler spieler) {
    List abwesendList = spieler.abwesendStr!.split(';');
    List<TableRow> rowList = [];
    if (!global.nurGrafik!) {
      rowList.add(_getRowAbwesend(context, spieler.vorname!, abwesendList));
    }
    rowList.add(_getRowGrafik(context, spieler, abwesendList));

    return Table(
      border: TableBorder(bottom: borderSide, verticalInside: borderSide),
      defaultColumnWidth: FixedColumnWidth(sizeDay),
      columnWidths: {
        0: FixedColumnWidth(sizeName),
      },
      children: rowList,
    );
  }

  /// Row mit den Abwesenheiten eines Spielers
  TableRow _getRowAbwesend(BuildContext context, String header, List abwesendList) {
    return TableRow(children: _getCellAbwesend(context, header, abwesendList));
  }

  /// Alle Zellen für einen Spieler
  List<TableCell> _getCellAbwesend(BuildContext context, String header, List abwesendList) {
    List<TableCell> list = [];
    list.add(TableCell(
        child: Text(
      header, style: Theme.of(context).textTheme.labelLarge,
      overflow: TextOverflow.ellipsis,
    )));
    // die Abwesenheiten in Textform anzeigen
    for (int i = global.arrayStart; i < global.arrayEnd; i++) {
      if (i < abwesendList.length) {
        list.add(
          TableCell(child: Text(abwesendList[i],
              style: Theme.of(context).textTheme.labelLarge),
    ),
        );
      }
    }
    return list;
  }

  /// Row mit den grafischer Darstellung der Abwesenheiten eines Spielers
  TableRow _getRowGrafik(BuildContext context, Spieler spieler, List abwesendList) {
    return TableRow(children: _getCellGrafik(context, spieler, abwesendList));
  }

  /// Die einzelne Zelle zeichnen
  List<TableCell> _getCellGrafik(BuildContext context, Spieler spieler, List abwesendList) {
    List<TableCell> list = [];
    list.add(TableCell(
        child: Text(
      spieler.name!, style: Theme.of(context).textTheme.labelLarge,
          overflow: TextOverflow.ellipsis,
    )));
    for (int dayNr = global.arrayStart; dayNr < global.arrayEnd; dayNr++) {
      if (dayNr < abwesendList.length) {
        String abwTag = abwesendList[dayNr];
        abwTag = abwTag.trim();
        double abwStart = AbwesendBase.getPosStart(abwTag, dayNr);
        double abwEnd = AbwesendBase.getPosEnd(abwTag, dayNr, abwStart);
        // matches, wenn von diesem Tag
        List<MatchDisplay> matchDisplayList = AbwesendBase.getMatches(spieler, dayNr);
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



  /// Ist die Position im Array ein Weekend?
  bool isWeekend(int pos) {
    DateTime? datum = global.startDatum;
    datum = global.startDatum.add(Duration(days: pos));
//    for (int i = 0; i < global.arrayLen; i++) {
    return (datum.weekday >= 6);
    //   }
  }
}


