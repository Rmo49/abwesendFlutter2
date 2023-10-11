import 'package:flutter/material.dart';
import 'package:abwesend/model/spieler.dart';
import 'package:abwesend/model/globals.dart' as global;
import 'package:abwesend/pages/abwesend_base.dart';

/// Die Abwesenheiten ändern
class AbwesendEdit extends StatefulWidget {
  const AbwesendEdit({Key? key}) : super(key: key);

  @override
  AbwesendEditState createState() => AbwesendEditState();
}

class AbwesendEditState extends State<AbwesendEdit> {
  static const double colWidth = 40.0;
  Spieler? _spieler;
  List<String>? _abwesendList;
  final int _anzCol = global.arrayLenMax;
  late List<TextEditingController> _txtList;
  TextEditingController txtWochenwert = TextEditingController();
  TextEditingController txtMeldung = TextEditingController();

  @override
  void initState() {
    super.initState();
    readSpieler(global.spielerIdList);
  }

  /// Den ersten Spieler von der DB lesen
  Future readSpieler(List<int> spielerIdList) async {
    List<Spieler?> spielerList = [];
    if (spielerIdList.isNotEmpty) {
      Spieler? spieler = await Spieler.readSpieler(spielerIdList.elementAt(0));
      spielerList.add(spieler);
    } else {
      spielerList.clear();
    }
    doSetState(spielerList);
  }

  /// nachedem alles eingelesen wurde
  void doSetState(List<Spieler?> spielerList) {
    _spieler = spielerList.first;
    if (_spieler != null) {
      _abwesendList = _spieler!.abwesendStr!.split(';');
      _initTxtController();
    }
    setState(() {
      // _spieler;
    });
  }

  /// alle TextController initialisieren mit den init-Wert
  void _initTxtController() {
    _txtList = [];
    for (int i = 0; i < global.arrayLenMax; i++) {
      _txtList.add(TextEditingController());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_spieler == null) {
      return Scaffold(appBar: AppBar(title: const Text('Lade Daten')));
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Abwesenheiten eintragen'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.save),
              iconSize: 30.0,
              tooltip: 'Speichern',
              onPressed: () {
                _speichern();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Text(
              '${_spieler!.vorname!} ${_spieler!.name!}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                  border: TableBorder.all(color: Colors.grey),
                  defaultColumnWidth: const FixedColumnWidth(colWidth),
                  children: [
                    //Datum Zeile
                    TableRow(
                      children: AbwesendBase.getCellsDatum(
                          context, "Dat.", global.startDatum, _anzCol),
                    ),
                    TableRow(
                      children: AbwesendBase.getCellsAbwesend(
                          context, "Abw.", _abwesendList, 0, _anzCol),
                    ),

                    TableRow(
                      children: AbwesendBase.getCellsGrafik(
                          _spieler, _abwesendList, -1, _anzCol),
                    ),
                    TableRow(
                      children: _getTxtField("Wert", 0, _anzCol, context),
                    )
                  ]),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
              child: Column(
                children: [
                  Text.rich(TextSpan(children: <TextSpan>[
                    TextSpan(
                      text: "Beispiel für Werte: ",
                    ),
                    TextSpan(
                        text: " 0 = ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: "ganzer Tag abwesend")
                  ])),

                  Text.rich(TextSpan(children: <TextSpan>[
                    TextSpan(
                        text: "-18.30 = ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: " kann bis 18.30 Uhr nicht spielen, "),
                    TextSpan(
                        text: "20- = ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: " kann nach 20 Uhr nicht spielen"),
                  ])),

                  Text.rich(TextSpan(children: <TextSpan>[
                    TextSpan(
                        text: "Speichern: ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: " (rechts oben) dann wird die Eingabe grafisch dargestellt, "),
                    ])),
                  Text.rich(TextSpan(children: <TextSpan>[
                    TextSpan(
                        text: " löschen: ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: " einfach leeren Text eingeben in der Ziele 'Wert' "),
                  ])),

                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: txtWochenwert,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: "Wert",
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0)))),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 10),
                  child: ElevatedButton(
                    child: const Text(
                        '<== diesen Wert in alle Wochentage eintragen'),
                    onPressed: () {
                      _setWochenwert();
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  maxLines: 3,
                  controller: txtMeldung,
                  readOnly: true,
                ),
              ),
            ),
          ],
        ));
  }

  /// Die Eingabefelder für jeden Tag
  List<TableCell> _getTxtField(
      String header, int von, int bis, BuildContext context) {
    List<TableCell> rowList = [];
    rowList.add(TableCell(child: Text(header)));

    for (int i = von; i < bis; i++) {
      rowList.add(
        TableCell(
            child: TextField(
          controller: _txtList[i],
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          style: Theme.of(context).textTheme.bodyMedium,
          onEditingComplete: () => FocusScope.of(context).nextFocus(),
        )),
      );
      _txtList[i].text = _abwesendList![i];
    }
    return rowList;
  }

  /// Wochenwert eintragen
  void _setWochenwert() {
    for (int i = 0; i < _anzCol; i++) {
      if (!AbwesendBase.isWeekend(i)) {
        _txtList[i].text = txtWochenwert.text;
      }
    }
  }

  /// Speichern des geänderten Spieler in DB
  void _speichern() async {
    for (int i = 0; i < _anzCol; i++) {
      _abwesendList![i] = _txtList[i].text;
    }
    _spieler!.abwesendStr = _abwesendList!.join(';');
    String result = await _spieler!.saveSpieler();
    setState(() {
      txtMeldung.text = result;
    });
  }
}
