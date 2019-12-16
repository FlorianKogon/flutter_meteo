import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Meteo Flutter Project'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<String> cities = ["Paris", "Bordeaux", "Nantes"];

  String chosenCity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.amber,
          child: ListView.builder(
            itemCount: cities.length + 2,
            itemBuilder: (context, i) {
              if (i == 0) {
                return DrawerHeader(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      textWithStyle("Mes Villes", fontsize: 22.0),
                      CupertinoButton(
                        color: Colors.white,
                        child: textWithStyle("Ajouter une ville", color: Colors.blue),
                        onPressed: addCity,
                      ),
                    ],
                  )
                );
              } else if (i == 1) {
                return ListTile(
                  title: textWithStyle("Ma ville actuelle"),
                  onTap: () {
                    setState(() {
                      chosenCity = null;
                      Navigator.pop(context);
                    });
                  },
                );
              } else {
                String city = cities[i - 2];
                return ListTile(
                  title: textWithStyle(city),
                  onTap: () {
                    setState(() {
                      chosenCity = city;
                      Navigator.pop(context);
                    });
                  },
                );
              }
          }),
        ),
      ),
      body: Center(
        child: Text((chosenCity == null)? "Ville actuelle" : chosenCity),
      ),
    );
  }

  Text textWithStyle(String data, {color: Colors.white, fontsize: 16.0, fontstyle: FontStyle.italic, textAlign: TextAlign.center}) {
    return Text(
    data,
    textAlign: TextAlign.center,
    style: TextStyle(
      color: color,
      fontSize: fontsize,
      fontStyle: fontstyle,
      ),
    );
  }

  Future addCity() async {
    return showDialog(
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SimpleDialog(
          contentPadding: EdgeInsets.all(20.0),
          title: textWithStyle("Ajoutez une ville", fontsize: 20.0, color: Colors.blue),
          children: <Widget>[
            CupertinoTextField(
              placeholder: 'Ville',
              onSubmitted: (String string) {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
      context: context
    );
  }
}