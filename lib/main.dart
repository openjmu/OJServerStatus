import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:openjmu_server_status/api.dart';
import 'package:openjmu_server_status/net_utils.dart';

void main() async {
  NetUtils.initConfig();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool firstCheck = true;
  bool requesting = true;
  Map<String, int> hostsStatus = {
    for (String key in API.hosts.keys) key: 0,
  };
  Map<String, bool> hostsRequesting = {
    for (String key in API.hosts.keys) key: true,
  };
  Map<String, String> hostsError = {
    for (String key in API.hosts.keys) key: null,
  };
  Timer timer;

  @override
  void initState() {
    requestStatus();
    timer ??= Timer.periodic(const Duration(seconds: 20), (_) {
      requestStatus();
    });
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void requestStatus() {
    NetUtils.dio.clear();
    if (firstCheck)
      hostsRequesting = {
        for (String key in API.hosts.keys) key: true,
      };
    requesting = true;
    if (mounted) setState(() {});

    Future.wait(
      List<Future>.generate(
        API.hosts.keys.length,
        (index) {
          final key = API.hosts.keys.elementAt(index);
          final request = API.hosts[key];
          return NetUtils.get(request).then((response) {
            hostsRequesting[key] = false;
            hostsStatus[key] = 1;
            if (hostsError[key] != null) hostsError[key] = null;
            if (mounted) setState(() {});
          }).catchError((e) {
            hostsRequesting[key] = false;
            hostsStatus[key] = 2;
            hostsError[key] = (e.message.toString() ?? e.type.toString() ?? e.toString());
            if (mounted) setState(() {});
          });
        },
      ),
    ).then((_) {
      firstCheck = false;
      requesting = false;
      if (mounted) setState(() {});
    }).catchError((e) {
      debugPrint("Error: $e");
      requesting = false;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Server status"),
        centerTitle: true,
        actions: <Widget>[
          if (requesting)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoActivityIndicator(),
            ),
        ],
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            for (String key in hostsStatus.keys)
              Card(
                margin: const EdgeInsets.all(6.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.cloud_circle),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  "$key",
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (hostsError[key] != null || hostsStatus[key] == 1)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                    ),
                                    child: Icon(
                                      hostsStatus[key] == 1
                                          ? Icons.check_circle_outline
                                          : Icons.error_outline,
                                      size: 16.0,
                                      color: hostsStatus[key] == 1 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                if (hostsError[key] != null)
                                  Expanded(
                                    child: Text(
                                      "${hostsError[key]}",
                                      maxLines: 1,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
