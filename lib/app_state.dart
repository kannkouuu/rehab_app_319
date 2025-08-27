import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

class FFAppState extends ChangeNotifier {
  static final FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal() {
    initializePersistedState();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _a1 = prefs.getString('ff_a1') ?? _a1;
    _notice = prefs.getString('ff_notice') ?? _notice;
    _gender = prefs.getString('ff_gender') ?? _gender;
    _imageboy = prefs.getString('ff_imageboy') ?? _imageboy;
    _imagegirl = prefs.getString('ff_imagegirl') ?? _imagegirl;
    _avatar = prefs.getString('ff_avatar') ?? _avatar;
    _timepicker = prefs.containsKey('ff_timepicker')
        ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt('ff_timepicker')!)
        : _timepicker;
    _joindate = prefs.containsKey('ff_joindate')
        ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt('ff_joindate')!)
        : _joindate;
    _name = prefs.getString('ff_name') ?? _name;
    _urgenname = prefs.getString('ff_urgenname') ?? _urgenname;
    _nickname = prefs.getString('ff_nickname') ?? _nickname;
    _phone = prefs.getString('ff_phone') ?? _phone;
    _nickphone = prefs.getString('ff_nickphone') ?? _nickphone;
    _urgername = prefs.getString('ff_urgername') ?? _urgername;
    _diagnosis = prefs.getString('ff_diagnosis') ?? _diagnosis;
    _affectedside = prefs.getString('ff_affectedside') ?? _affectedside;
    _accountnumber = prefs.getString('ff_accountnumber') ?? _accountnumber;
    _trainup = prefs.getString('ff_trainup') ?? _trainup;
    _traindown = prefs.getString('ff_traindown') ?? _traindown;
    _mouth = prefs.getString('ff_mouth') ?? _mouth;
    _password = prefs.getString('ff_password') ?? _password;
    _time = prefs.containsKey('ff_time')
        ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt('ff_time')!)
        : _time;
    _timecycle = prefs.containsKey('ff_timecycle')
        ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt('ff_timecycle')!)
        : _timecycle;
    _hasUnreadNotifications =
        prefs.getBool('ff_hasUnreadNotifications') ?? _hasUnreadNotifications;
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  String _a1 = '';
  String get a1 => _a1;
  set a1(String _value) {
    _a1 = _value;
    prefs.setString('ff_a1', _value);
  }

  String _notice = '';
  String get notice => _notice;
  set notice(String _value) {
    _notice = _value;
    prefs.setString('ff_notice', _value);
  }

  String _gender = '';
  String get gender => _gender;
  set gender(String _value) {
    _gender = _value;
    prefs.setString('ff_gender', _value);
  }

  String _imageboy =
      'https://www.creativefabrica.com/wp-content/uploads/users/2019/08/avatar_393721.jpg';
  String get imageboy => _imageboy;
  set imageboy(String _value) {
    _imageboy = _value;
    prefs.setString('ff_imageboy', _value);
  }

  String _imagegirl =
      'https://moytaganskiy.ru/imgs/org/962/15962/narkologicheskaya-klinika-reabilitaciya-plyus_6.webp';
  String get imagegirl => _imagegirl;
  set imagegirl(String _value) {
    _imagegirl = _value;
    prefs.setString('ff_imagegirl', _value);
  }

  String _avatar =
      'https://www.creativefabrica.com/wp-content/uploads/users/2019/08/avatar_393721.jpg';
  String get avatar => _avatar;
  set avatar(String _value) {
    _avatar = _value;
    prefs.setString('ff_avatar', _value);
  }

  DateTime? _timepicker;
  DateTime? get timepicker => _timepicker;
  set timepicker(DateTime? _value) {
    _timepicker = _value;
    _value != null
        ? prefs.setInt('ff_timepicker', _value.millisecondsSinceEpoch)
        : prefs.remove('ff_timepicker');
  }

  String _name = '';
  String get name => _name;
  set name(String _value) {
    _name = _value;
    prefs.setString('ff_name', _value);
  }

  String _urgenname = '';
  String get urgenname => _urgenname;
  set urgenname(String _value) {
    _urgenname = _value;
    prefs.setString('ff_urgenname', _value);
  }

  String _nickname = '';
  String get nickname => _nickname;
  set nickname(String _value) {
    _nickname = _value;
    prefs.setString('ff_nickname', _value);
  }

  String _phone = '';
  String get phone => _phone;
  set phone(String _value) {
    _phone = _value;
    prefs.setString('ff_phone', _value);
  }

  String _nickphone = '';
  String get nickphone => _nickphone;
  set nickphone(String _value) {
    _nickphone = _value;
    prefs.setString('ff_nickphone', _value);
  }

  String _urgername = '';
  String get urgername => _urgername;
  set urgername(String _value) {
    _urgername = _value;
    prefs.setString('ff_urgername', _value);
  }

  String _diagnosis = '';
  String get diagnosis => _diagnosis;
  set diagnosis(String _value) {
    _diagnosis = _value;
    prefs.setString('ff_diagnosis', _value);
  }

  String _affectedside = '';
  String get affectedside => _affectedside;
  set affectedside(String _value) {
    _affectedside = _value;
    prefs.setString('ff_affectedside', _value);
  }

  String _accountnumber = '';
  String get accountnumber => _accountnumber;
  set accountnumber(String _value) {
    _accountnumber = _value;
    prefs.setString('ff_accountnumber', _value);
  }

  String _trainup = '';
  String get trainup => _trainup;
  set trainup(String _value) {
    _trainup = _value;
    prefs.setString('ff_trainup', _value);
  }

  String _traindown = '';
  String get traindown => _traindown;
  set traindown(String _value) {
    _traindown = _value;
    prefs.setString('ff_traindown', _value);
  }

  String _mouth = '';
  String get mouth => _mouth;
  set mouth(String _value) {
    _mouth = _value;
    prefs.setString('ff_mouth', _value);
  }

  String _password = '';
  String get password => _password;
  set password(String _value) {
    _password = _value;
    prefs.setString('ff_password', _value);
  }

  DateTime? _time;
  DateTime? get time => _time;
  set time(DateTime? _value) {
    _time = _value;
    _value != null
        ? prefs.setInt('ff_time', _value.millisecondsSinceEpoch)
        : prefs.remove('ff_time');
  }

  DateTime? _timecycle;
  DateTime? get timecycle => _timecycle;
  set timecycle(DateTime? _value) {
    _timecycle = _value;
    _value != null
        ? prefs.setInt('ff_timecycle', _value.millisecondsSinceEpoch)
        : prefs.remove('ff_timecycle');
  }

  DateTime? _joindate;
  DateTime? get joindate => _joindate;
  set joindate(DateTime? _value) {
    _joindate = _value;
    _value != null
        ? prefs.setInt('ff_joindate', _value.millisecondsSinceEpoch)
        : prefs.remove('ff_joindate');
  }

  bool _hasUnreadNotifications = false;
  bool get hasUnreadNotifications => _hasUnreadNotifications;
  set hasUnreadNotifications(bool _value) {
    _hasUnreadNotifications = _value;
    prefs.setBool('ff_hasUnreadNotifications', _value);
    notifyListeners(); // 通知UI更新
  }

  // 檢查未讀訊息的方法
  Future<void> checkUnreadNotifications() async {
    if (_accountnumber.isEmpty) {
      return;
    }

    try {
      const String ip = 'https://hpds.klooom.com:10073/flutterphp/';
      var url = Uri.parse(ip + "getdata2.php");

      // 設定較短的超時時間，避免長時間等待
      final response = await http.post(
        url,
        body: {
          "account": _accountnumber,
          "time": "",
        },
      ).timeout(
        const Duration(seconds: 10), // 10秒超時
        onTimeout: () {
          throw TimeoutException('網路請求超時', const Duration(seconds: 10));
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          // 檢查是否有read_yet為0或"0"的通知
          bool hasUnread = data.any((item) {
            final readYet = item['read_yet'];
            return readYet == '0' || readYet == 0;
          });
          hasUnreadNotifications = hasUnread;
        }
      } else {
        // HTTP錯誤狀態碼，但不打印錯誤訊息（避免過多日誌）
        // 可以選擇在調試模式下打印
        // print('HTTP錯誤: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      // 網路連接問題（如DNS解析失敗、無網路連接等）
      // 在調試模式下才打印詳細錯誤，正式版本靜默處理
      assert(() {
        print('網路連接錯誤: $e');
        return true;
      }());
      // 網路問題時，保持當前通知狀態不變
    } on TimeoutException catch (e) {
      // 網路超時
      assert(() {
        print('網路請求超時: $e');
        return true;
      }());
    } on FormatException catch (e) {
      // JSON解析錯誤
      assert(() {
        print('資料格式錯誤: $e');
        return true;
      }());
    } catch (e) {
      // 其他未預期的錯誤
      assert(() {
        print('檢查未讀訊息時發生未知錯誤: $e');
        return true;
      }());
    }
  }

  // 手動設置未讀狀態的方法（當用戶進入通知頁面時使用）
  void markNotificationsAsChecked() {
    hasUnreadNotifications = false;
  }
}

LatLng? _latLngFromString(String? val) {
  if (val == null) {
    return null;
  }
  final split = val.split(',');
  final lat = double.parse(split.first);
  final lng = double.parse(split.last);
  return LatLng(lat, lng);
}
