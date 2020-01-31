import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class NetUtils {
  static final Dio dio = Dio();
  static final CookieJar cookieJar = CookieJar();
  static final CookieManager cookieManager = CookieManager(cookieJar);

  static void initConfig() async {
    dio.options.connectTimeout = 10000;
    dio.options.receiveTimeout = 10000;
    dio.interceptors.add(cookieManager);
    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioError e) {
        debugPrint("$e");
        return e;
      },
    ));
  }

  static Future get(String url, {data}) async => (await dio.get(url, queryParameters: data));
}
