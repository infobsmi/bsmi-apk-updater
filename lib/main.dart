import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, UpdateItem>> fetchAlbum() async {
  var installedAppFuture = await InstalledApps.getInstalledApps(true, true);

  List<String> installedAppList = List<String>.empty(growable: true);
  installedAppFuture.forEach((element) {
    installedAppList.add(element.packageName);
  });

  final response = await http.post(
    Uri.https('update.bsmi.info', 'api/'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, List<String>>{
      'appList': installedAppList,
    }),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    //   developer.log("response.body:", error: response.body);
    var bodyList = (jsonDecode(response.body) as List)
        .map((i) => UpdateItem.fromJson(i))
        .toList();
    ;
    var outMap = new Map<String, UpdateItem>();
    bodyList.forEach((element) {
      outMap[element.guid] = element;
    });
    //developer.log("outMap: ", error: outMap.toString());
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
      title: 'Android应用升级检测程序',
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
      home: MyHomePage(title: 'Android应用升级检测程序'),
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




void _openUrl(String _url) async => await canLaunch(_url)
    ? await launch(_url)
    : throw 'Could not launch $_url';

class InstalledAppsScreen extends StatelessWidget {
  Map<String, UpdateItem> updateInfo;
  List<AppInfo> appInfo;

  InstalledAppsScreen({this.updateInfo});

  Future queryAppUpdate() async {
    appInfo = await InstalledApps.getInstalledApps(true, true);
    updateInfo = await fetchAlbum();
  }

  Future<UpdateItem> buildVersionNumber(
      String versionName, String packageName) async {
    if (updateInfo.containsKey(packageName)) {
      var tmpUpdateInfo = updateInfo[packageName];
      // var tmpStr = tmpUpdateInfo.toString();
      developer.log("Find the updateInfo: packageName: " +
          tmpUpdateInfo.guid +
          tmpUpdateInfo.link);
      if (tmpUpdateInfo.version != versionName) {
        return tmpUpdateInfo;
      }
    }

    developer.log(packageName + ":version");

    developer.log("installed app: $packageName it's version: $versionName");

    return UpdateItem(
        link: "", guid: packageName, version: versionName, ts: '');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("已安装应用列表"),
        ),
        body: FutureBuilder(
            future: queryAppUpdate(),
            builder: (BuildContext buildContext, snapshot) {
              return snapshot.connectionState == ConnectionState.done
                  ? ListView.builder(
                      itemCount: appInfo.length,
                      itemBuilder: (context, index) {
                        AppInfo app = appInfo[index];
                        developer.log("the appInfo:" + app.packageName  + " the appVersion: " + app.versionName);
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: Image.memory(app.icon),
                            ),
                            title: Text(app.name),
                            subtitle: FutureBuilder<UpdateItem>(
                              future: buildVersionNumber(
                                  app.versionName, app.packageName),
                              builder: (BuildContext buildContext,
                                  AsyncSnapshot<UpdateItem> snapshot) {
                                return snapshot.connectionState ==
                                        ConnectionState.done
                                    ? snapshot.hasData
                                        ? (snapshot.data.link == ""
                                            ? Text(snapshot.data.version)
                                            : InkWell(
                                                onTap: () {
                                                  _openUrl(snapshot.data.link);
                                                },
                                                child: Text("需要升级，当前版本：" +
                                                    app.versionName +
                                                    ", 最新版本：" +
                                                    snapshot.data.version),
                                              ))
                                        : Text("Error when get version number")
                                    : Text("Queryring update");
                              },
                            ),
                            /*onLongPress: () =>
                                InstalledApps.openSettings(app.packageName),*/
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
        appBar: AppBar(title: const Text("Android应用升级检测程序")),
        body: ListView(children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("己安装应用列表"),
                subtitle: Text(
                    "获取系统己安装的应用列表，并检测更新"),
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
                title: Text("开发者"),
                subtitle: Text("版权所有 netroby 2000-2021, 源代码以AGPL 协议开源！"),
                onTap: () =>  _openUrl("https://www.netroby.com")
              ),
            ),
          )
        ]));
  }
}
