import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, UpdateItem>> fetchAlbum() async  {
  var installedAppFuture = await InstalledApps.getInstalledApps(true, true);

  List<String> installedAppList = List<String>.empty(growable: true);
  installedAppFuture.forEach((element) {
    installedAppList.add(element.packageName);
  });


  final response = await http.post(Uri.https('update.bsmi.info', 'api/'),
    headers: <String, String>{
    'Content-Type': 'application/json; charset=UTF-8',
  },
    body: jsonEncode(<String, List<String>>{
      'appList': installedAppList,
    }),);

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    //   developer.log("response.body:", error: response.body);
    var bodyList =  (jsonDecode(response.body) as List)
        .map((i) => UpdateItem.fromJson(i))
        .toList();;
    var outMap = new Map<String, UpdateItem>();
    bodyList.forEach((element) {
      outMap[element.guid] = element;
    });
    developer.log("outMap: ", error: outMap.toString());
    return outMap;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load ');
  }
}

class UpdateItem {
  /**
   * "link": "https://apkcombo.com/hack-pubg/com.elhamditarik9.bbattleground/",
      "guid": "com.elhamditarik9.bbattleground",
      "ts": "Tue, 05 Apr 2022 12:00:00 +0000",
      "version": "13.0.2"
   */
  final String link;
  final String guid;
  final String ts;
  final String version;

  UpdateItem(
      {@required this.link,
      @required this.guid,
      @required this.ts,
      @required this.version});

  factory UpdateItem.fromJson(Map<String, dynamic> json) {
    return UpdateItem(
      link: json['link'],
      guid: json['guid'],
      ts: json['ts'],
      version: json['version'],
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class AppInfoScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("App Info"),
        ),
        body: FutureBuilder<AppInfo>(
            future: InstalledApps.getAppInfo("com.google.android.gm"),
            builder:
                (BuildContext buildContext, AsyncSnapshot<AppInfo> snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                developer.log("Appinfo:",
                    error: jsonEncode(snapshot.data.packageName));
              }
              return snapshot.connectionState == ConnectionState.done
                  ? snapshot.hasData
                      ? Center(
                          child: Column(
                            children: [
                              Image.memory(snapshot.data.icon),
                              Text(snapshot.data.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 40)),
                              Text(snapshot.data.getVersionInfo()),
                              Text("无需更新")
                            ],
                          ),
                        )
                      : Center(child: Text("Erro while getting app info ...."))
                  : Center(child: Text("Getting app info ...."));
            }));
  }
}

class InstalledAppsScreen extends StatelessWidget {


  Map<String, UpdateItem> updateInfo;
  List<AppInfo> appInfo;

InstalledAppsScreen({this.updateInfo});



  Future queryAppUpdate() async {
    appInfo =  await InstalledApps.getInstalledApps(true, true);
    updateInfo = await fetchAlbum();
  }

  Future<String> buildVersionNumber(String versionInfo, String packageName) async {


    if (updateInfo.containsKey(packageName)) {
      var tmpUpdateInfo = updateInfo[packageName];
     // var tmpStr = tmpUpdateInfo.toString();
      developer.log("Find the updateInfo: packageName: " + tmpUpdateInfo.guid + tmpUpdateInfo.link );
     // if (tmpUpdateInfo.version != versionInfo) {
        return "需要更新: " + tmpUpdateInfo.link;
    //  }
    }

    developer.log(packageName + ":version");

      developer.log("installed app: $packageName it's version: $versionInfo");

    return (versionInfo + " [无需更新]");

  }

  @override
  Widget build(BuildContext context) {



    return Scaffold(
        appBar: AppBar(
          title: Text("Installed Apps"),
        ),
        body: FutureBuilder(
            future: queryAppUpdate(),
            builder: (BuildContext buildContext,
                  snapshot) {
              return snapshot.connectionState == ConnectionState.done

                      ? ListView.builder(
                          itemCount: appInfo.length,
                          itemBuilder: (context, index) {
                            AppInfo app = appInfo[index];
                            developer.log("the appInfo:",
                                error: app.packageName);
                            developer.log("the appVersion", error: app.getVersionInfo());
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: Image.memory(app.icon),
                                ),
                                title: Text(app.name),
                                subtitle: FutureBuilder<String> (
                                  future: buildVersionNumber(app.getVersionInfo(), app.packageName),
                                      builder: (BuildContext buildContext, AsyncSnapshot<String> snapshot) {
                                    return snapshot.connectionState == ConnectionState.done
                                        ? snapshot.hasData
                                        ? Text(snapshot.data)
                                        : Text("Error when get version number")
                                   : Text("Queryring update")
                                    ;
                              },
                                ),
                                    onTap: () =>
                                    InstalledApps.startApp(app.packageName),
                                onLongPress: () =>
                                    InstalledApps.openSettings(app.packageName),
                              ),
                            );
                          })
                  : Center(child: Text("Getting installed apps ...."));
            }));
  }



}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  Future<Map<String, UpdateItem>> futureAlbum;
  Map<String, UpdateItem> updateInfo;

  @override
  void initState() {
    super.initState();
    fetchAlbum().then((value) => {updateInfo = value});
    developer.log("updateInfo : ", error: jsonEncode(updateInfo));
  }

  void _showDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(text),
          actions: <Widget>[
            FlatButton(
              child: Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(title: const Text("Installed Apps Example")),
        body: ListView(children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Installed Apps"),
                subtitle: Text(
                    "Get installed apps on device. With options to exclude system app, get app icon & matching package name prefix."),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => InstalledAppsScreen(
                         updateInfo: this.updateInfo,
                      )),
                ),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("App Info"),
                subtitle: Text("Get app info with package name"),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AppInfoScreen()),
                ),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Start App"),
                subtitle: Text(
                    "Start app with package name. Get callback of success or failure."),
                onTap: () => InstalledApps.startApp("com.google.android.gm"),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Go To App Settings Screen"),
                subtitle: Text(
                    "Directly navigate to app settings screen with package name"),
                onTap: () =>
                    InstalledApps.openSettings("com.google.android.gm"),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Check If System App"),
                subtitle: Text("Check if app is system app with package name"),
                onTap: () => InstalledApps.isSystemApp("com.google.android.gm")
                    .then((value) => _showDialog(
                        context,
                        value
                            ? "The requested app is system app."
                            : "Requested app in not system app.")),
              ),
            ),
          )
        ]));
  }
}
