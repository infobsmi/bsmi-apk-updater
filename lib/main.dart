import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Installed Apps"),
        ),
        body: FutureBuilder<List<AppInfo>>(
            future: InstalledApps.getInstalledApps(true, true),
            builder: (BuildContext buildContext,
                AsyncSnapshot<List<AppInfo>> snapshot) {
              return snapshot.connectionState == ConnectionState.done
                  ? snapshot.hasData
                      ? ListView.builder(
                          itemCount: snapshot.data.length,
                          itemBuilder: (context, index) {
                            AppInfo app = snapshot.data[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: Image.memory(app.icon),
                                ),
                                title: Text(app.name),
                                subtitle: Text(app.getVersionInfo()  + " [无需更新]"),
                                onTap: () =>
                                    InstalledApps.startApp(app.packageName),
                                onLongPress: () =>
                                    InstalledApps.openSettings(app.packageName),
                              ),
                            );
                          })
                      : Center(
                          child: Text(
                              "Error occurred while getting installed apps ...."))
                  : Center(child: Text("Getting installed apps ...."));
            }));
  }
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

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
      body: ListView(
        children: [
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
                      builder: (context) => InstalledAppsScreen()),
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
        ],
      ),
    );
  }
}
