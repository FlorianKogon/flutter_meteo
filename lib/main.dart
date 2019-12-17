import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:geocoder/geocoder.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_meteo/temperature.dart';
import 'my_flutter_app_icons.dart';

Future main() async {
  await DotEnv().load('.env');
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weatherino',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: MyHomePage(title: 'Weatherino'),
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

  Temperature temperature;

  String key = "Villes";
  List<String> cities = [];
  String chosenCity;

  Location location;
  LocationData locationData;
  Stream<LocationData> stream;
  Coordinates coordChosenCity;

  AssetImage night = AssetImage("assets/n.jpg");
  AssetImage sun = AssetImage("assets/d1.jpg");
  AssetImage rain = AssetImage("assets/d2.jpg");

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getSharedPreferences();
    location = Location();
    //getFirstLocation();
    listenToStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: Container(
          child: ListView.builder(
            itemCount: cities.length + 2,
              itemBuilder: (context, i) {
              if (i == 0) {
                return DrawerHeader(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      styledText("Mes villes", fontSize: 24.0, fontWeight: FontWeight.bold),
                      CupertinoButton(
                        color: Colors.white,
                        child: styledText("Ajouter une ville", color: Colors.blue[800], fontWeight: FontWeight.bold),
                        onPressed: addCity,
                      ),
                    ],
                  ),
                );
              } else if (i == 1) {
                return new ListTile(
                  title: styledText("Ma ville actuelle"),
                  onTap: () {
                    setState(() {
                      chosenCity = null;
                      coordChosenCity = null;
                      Navigator.pop(context);
                    });
                  },
                );
              } else {
                String city = cities[i - 2];
                return ListTile(
                  title: styledText(city),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.white),
                    onPressed: (() => delete(city)),
                  ),
                  onTap: () {
                    setState(() {
                      chosenCity = city;
                      locationToCoordinates();
                      Navigator.pop(context);
                    });
                  },
                );
              }
              }),
          color: Colors.blue[800],
        ),
      ),
      body: (temperature == null)
        ? Center(child: Text((chosenCity == null)? "Ville actuelle": chosenCity))
        : Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          image: DecorationImage(image : getBackground(), fit: BoxFit.cover)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            styledText((chosenCity == null)? "Ville Actuelle" : chosenCity, fontSize: 40.0),
            styledText(temperature.description, fontSize: 30.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Image(image: getIcon()),
                styledText("${temperature.temp.toInt()} °C", fontSize: 50.0)
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                extra("${temperature.min.toInt()} °C", MyFlutterApp.down_outline),
                extra("${temperature.max.toInt()} °C", MyFlutterApp.up_outline),
                extra("${temperature.pressure.toInt()} hPa", MyFlutterApp.temperatire),
                extra("${temperature.humidity.toInt()} %", MyFlutterApp.rain),
              ],
            )
          ],
        ),
      ),
    );
  }

  Text styledText(String data, {color: Colors.white, fontSize: 18.0, fontStyle: FontStyle.normal, textAlign: TextAlign.left, fontWeight: FontWeight.w400}) {
    return Text(
      data,
      textAlign: textAlign,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontStyle: fontStyle,
        fontWeight: fontWeight,
      ),
    );
  }

  Column extra(String data, IconData iconData) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Icon(iconData, color: Colors.white, size: 32.0),
        styledText(data),
      ],
    );
  }

  Future<Null> addCity() async {
    return showDialog(
      barrierDismissible: true,
        builder: (BuildContext buildContext) {
          return SimpleDialog(
            contentPadding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
            title: styledText("Ajouter une ville", fontSize: 24.0, color: Colors.blue[800]),
            children: <Widget>[
              CupertinoTextField(
                placeholder: "Ville",
                autofocus: true,
                onSubmitted: (String str) {
                  add(str);
                  Navigator.pop(buildContext);
                },
              ),
            ],
          );
        },
        context: context
    );
  }

  // ------ Location ------
  // Once
  getFirstLocation() async {
    try {
      locationData = await location.getLocation();
      print("Nouvelle position : ${locationData.latitude} / ${locationData.longitude}");
      locationToString();
    } catch (e) {
      print("Error: $e");
    }
  }

// Each Change
  listenToStream() {
    stream = location.onLocationChanged();
    stream.listen((newPosition) {
      if ((locationData == null) || (newPosition.longitude != locationData.longitude) && (newPosition.latitude != locationData.latitude)) {
        setState(() {
          print("New => ${newPosition.latitude} ------ ${newPosition.longitude}");
          locationData = newPosition;
          locationToString();
        });
      }
    });
  }

  // ------ SharedPreferences ------

  void getSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List<String> list = await sharedPreferences.getStringList(key);
    if (list != null) {
      setState(() {
        cities = list;
      });
    }
  }

  void add(String str) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    cities.add(str);
    await sharedPreferences.setStringList(key, cities);
    getSharedPreferences();
  }

  void delete(String str) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    cities.remove(str);
    await sharedPreferences.setStringList(key, cities);
    getSharedPreferences();
  }

  // ------ AssetImage -------
  AssetImage getBackground() {
    print(temperature.icon);
    if (temperature.icon.contains("n")) {
      return night;
    } else {
      if (temperature.icon.contains("01") || temperature.icon.contains("02") || temperature.icon.contains("03")) {
        return sun;
      } else {
        return rain;
      }
    }
  }

  AssetImage getIcon() {
    String icon = temperature.icon.replaceAll("d", "").replaceAll("n", "");
    return AssetImage("assets/$icon.png");
  }

  // ------ Geocoder ------

  locationToString() async {
    if (locationData != null) {
      Coordinates coordinates = Coordinates(locationData.latitude, locationData.longitude);
      final cityName = await Geocoder.local.findAddressesFromCoordinates(coordinates);
      apiCall();
    }
  }

  locationToCoordinates() async {
    if (chosenCity != null) {
      List<Address> addresses = await Geocoder.local.findAddressesFromQuery(chosenCity);
      if (addresses.length > 0) {
        Address address = addresses.first;
        Coordinates coordinates = address.coordinates;
        setState(() {
          coordChosenCity = coordinates;
          apiCall();
        });
      }
    }
  }

  apiCall() async {
    double latitude;
    double longitude;
    if (coordChosenCity != null) {
      latitude = coordChosenCity.latitude;
      longitude = coordChosenCity.longitude;
    } else if (locationData != null) {
      latitude = locationData.latitude;
      longitude = locationData.longitude;
    }

    if (latitude != null && longitude != null) {
      final key = "&APPID=${DotEnv().env['API_KEY']}";
      String language = "&lang=${Localizations.localeOf(context).languageCode}";
      String baseAPI = 'http://api.openweathermap.org/data/2.5/weather?';
      String coordsString = "lat=$latitude&lon=$longitude";
      String units = '&units=metric';
      String totalRequest = baseAPI + coordsString + units + language + key;
      final response = await http.get(totalRequest);
      if (response.statusCode == 200) {
        print(response.body);
        Map map = jsonDecode(response.body);
        setState(() {
          temperature = Temperature(map);
          print(temperature.description);
        });
      }
    }
  }
}
