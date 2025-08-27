import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/bottom_navigation.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'setting_model.dart';
export 'setting_model.dart';
import 'package:http/http.dart' as http;
import '/main.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';

class SettingWidget extends StatefulWidget {
  const SettingWidget({Key? key}) : super(key: key);

  @override
  _SettingWidgetState createState() => _SettingWidgetState();
}

class _SettingWidgetState extends State<SettingWidget> {
  late SettingModel _model;

  var age1; //取得年齡
  var a = DateTime.now(); //取得現在日期
  bool _isLoading = false; //載入狀態

  // 載入用戶資料
  Future<void> loadUserData() async {
    if (FFAppState().accountnumber == null ||
        FFAppState().accountnumber!.isEmpty) {
      print("帳號為空，無法載入資料");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var url = Uri.parse(ip + "getUserData.php");

      final response = await http.post(url, body: {
        "account": FFAppState().accountnumber!,
      });

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          final userData = jsonResponse['data'];

          // 填入 TextController
          _model.textController1?.text = userData['name'] ?? '';
          _model.textController2?.text = userData['nickname'] ?? '';
          _model.textController3?.text = userData['phone'] ?? '';
          _model.textController4?.text = userData['urgenname'] ?? '';
          _model.textController5?.text = userData['urgenphone'] ?? '';

          // 更新 FFAppState
          FFAppState().name = userData['name'] ?? '';
          FFAppState().nickname = userData['nickname'] ?? '';
          FFAppState().phone = userData['phone'] ?? '';
          FFAppState().urgenname = userData['urgenname'] ?? '';
          FFAppState().nickphone = userData['urgenphone'] ?? '';
          FFAppState().gender = userData['gender'] ?? '';
          FFAppState().diagnosis = userData['diagnosis'] ?? '';
          FFAppState().affectedside = userData['affectedside'] ?? '';

          // 更新下拉選單的控制器和值
          _model.dropDownValue1 = userData['diagnosis'] ?? '';
          _model.dropDownValue2 = userData['affectedside'] ?? '';

          // 重新設定 FormFieldController 的值
          _model.dropDownValueController1?.value = _model.dropDownValue1;
          _model.dropDownValueController2?.value = _model.dropDownValue2;

          // 處理日期欄位
          if (userData['birthday'] != null && userData['birthday'].isNotEmpty) {
            try {
              FFAppState().timepicker = DateTime.parse(userData['birthday']);
            } catch (e) {
              print("生日日期解析錯誤: $e");
              FFAppState().timepicker = null;
            }
          }

          if (userData['joindate'] != null && userData['joindate'].isNotEmpty) {
            try {
              FFAppState().joindate = DateTime.parse(userData['joindate']);
            } catch (e) {
              print("加入日期解析錯誤: $e");
              // 如果解析失敗，保持原值或設為今天
              if (FFAppState().joindate == null) {
                FFAppState().joindate = DateTime.now();
              }
            }
          } else {
            // 如果資料庫中沒有加入日期，且當前也沒有值，則設為今天
            if (FFAppState().joindate == null) {
              FFAppState().joindate = DateTime.now();
            }
          }

          // 根據性別設定頭像
          if (FFAppState().gender == '女') {
            FFAppState().avatar = FFAppState().imagegirl;
          } else if (FFAppState().gender == '男') {
            FFAppState().avatar = FFAppState().imageboy;
          }

          // 更新 UI
          setState(() {});

          print("用戶資料載入成功");
        } else {
          print("載入失敗: ${jsonResponse['message']}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('載入資料失敗: ${jsonResponse['message']}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        print("HTTP 請求失敗: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('網路請求失敗: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("載入用戶資料時發生錯誤: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('載入資料時發生錯誤: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> editData() async {
    try {
      // 計算年齡
      if (FFAppState().timepicker != null) {
        age1 = getAge(FFAppState().timepicker as DateTime);
      } else {
        age1 = "0";
      }

      var url = Uri.parse(ip + "editdata1.php");

      // 準備要發送的資料，確保所有值都不是 null
      Map<String, String> postData = {
        "name": _model.textController1?.text?.trim() ?? "",
        "nickname": _model.textController2?.text?.trim() ?? "",
        "phone": _model.textController3?.text?.trim() ?? "",
        "urgenname": _model.textController4?.text?.trim() ?? "",
        "urgenphone": _model.textController5?.text?.trim() ?? "",
        "birthday": FFAppState().timepicker?.toString() ?? "",
        "gender": FFAppState().gender?.toString() ?? "",
        "diagnosis": FFAppState().diagnosis?.toString() ?? "",
        "account": FFAppState().accountnumber?.toString() ?? "",
        "affectedside": FFAppState().affectedside?.toString() ?? "",
        "age": age1?.toString() ?? "0",
        "joindate": FFAppState().joindate?.toString() ?? "",
      };

      // 發送 HTTP 請求
      final response = await http.post(url, body: postData);

      // 檢查響應狀態
      if (response.statusCode == 200) {
        // 伺服器回應
        if (response.body.isNotEmpty) {
          print("伺服器回應: ${response.body}");
        }

        // 顯示成功訊息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('資料已成功儲存'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // HTTP 錯誤
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('儲存失敗：HTTP ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 處理異常
      print("儲存資料時發生錯誤: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('儲存失敗：$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String getAge(DateTime brt) {
    //年齡
    int age = 0;
    DateTime dateTime = DateTime.now();
    if (dateTime.isBefore(brt)) {
      //出生日期晚於當前時間，無法計算
      return '出生日期不正確';
    }
    int yearNow = dateTime.year; //當前年份
    int monthNow = dateTime.month; //當前月份
    int dayOfMonthNow = dateTime.day; //當前日期

    int yearBirth = brt.year;
    int monthBirth = brt.month;
    int dayOfMonthBirth = brt.day;
    age = yearNow - yearBirth; //計算整歲數
    if (monthNow <= monthBirth) {
      if (monthNow == monthBirth) {
        if (dayOfMonthNow < dayOfMonthBirth) age--; //當前日期在生日之前，年齡減一
      } else {
        age--; //當前月份在生日之前，年齡減一
      }
    }
    return age.toString();
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SettingModel());

    // 初始化 TextController（暫時用空值）
    _model.textController1 ??= TextEditingController();
    _model.textController2 ??= TextEditingController();
    _model.textController3 ??= TextEditingController();
    _model.textController4 ??= TextEditingController();
    _model.textController5 ??= TextEditingController();

    // 初始化下拉選單控制器
    _model.dropDownValueController1 ??= FormFieldController<String>(null);
    _model.dropDownValueController2 ??= FormFieldController<String>(null);

    // Initialize joindate if null, similar to FFAppState().time logic
    if (FFAppState().joindate == null) {
      FFAppState().joindate = DateTime.now();
    }

    // 載入用戶資料
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadUserData();
    });
  }

  @override
  void dispose() {
    _model.dispose();

    _unfocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Responsive dimensions
    final double appBarTitleFontSize =
        isLandscape ? screenHeight * 0.05 : screenWidth * 0.07;
    final double generalPadding =
        isLandscape ? screenWidth * 0.02 : screenWidth * 0.04;
    final double itemSpacing =
        isLandscape ? screenHeight * 0.02 : screenHeight * 0.02;

    final double avatarSize =
        isLandscape ? screenHeight * 0.22 : screenWidth * 0.28;
    final double labelFontSize =
        isLandscape ? screenHeight * 0.035 : screenWidth * 0.05;
    final double valueFontSize =
        isLandscape ? screenHeight * 0.032 : screenWidth * 0.045;
    final double textFieldHeight =
        isLandscape ? screenHeight * 0.08 : screenHeight * 0.055;
    final double dropDownWidth =
        isLandscape ? screenWidth * 0.35 : screenWidth * 0.68;
    final double dropDownHeight =
        isLandscape ? screenHeight * 0.1 : screenHeight * 0.07;
    final double buttonWidth =
        isLandscape ? screenWidth * 0.25 : screenWidth * 0.4;
    final double buttonHeight =
        isLandscape ? screenHeight * 0.1 : screenHeight * 0.06;
    final double buttonFontSize =
        isLandscape ? screenHeight * 0.035 : screenWidth * 0.05;

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_unfocusNode),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBtnText,
        body: SafeArea(
          top: true,
          bottom: false, // 關閉底部安全區域，讓導航欄可以貼合底部
          child: Column(
            // Main column for three-pane layout
            children: [
              // Top Bar - Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    vertical: isLandscape
                        ? screenHeight * 0.02
                        : screenHeight * 0.015,
                    horizontal: screenWidth * 0.05),
                color: Color(0xFF90BDF9), // Consistent color from other pages
                child: Text(
                  '個人設定',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).displaySmall.override(
                        fontFamily: 'Poppins',
                        fontSize: appBarTitleFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                ),
              ),

              // Middle Section - Scrollable Form Content
              Expanded(
                child: Container(
                  width: screenWidth,
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  padding: EdgeInsets.all(generalPadding),
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF90BDF9),
                              ),
                              SizedBox(height: 16),
                              Text(
                                '載入資料中...',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Poppins',
                                      fontSize: valueFontSize,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User avatar and basic info section - improved for landscape
                              Padding(
                                padding:
                                    EdgeInsets.only(bottom: generalPadding),
                                child: isLandscape
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0, 0, generalPadding, 0),
                                            child: CachedNetworkImage(
                                              imageUrl: FFAppState().avatar,
                                              width: avatarSize,
                                              height: avatarSize,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildInfoRow(
                                                    context,
                                                    '帳號 :',
                                                    FFAppState().accountnumber,
                                                    isLandscape,
                                                    labelFontSize,
                                                    valueFontSize,
                                                    readOnly: true),
                                                SizedBox(height: itemSpacing),
                                                _buildEditableInfoRow(
                                                    context,
                                                    '姓名 :',
                                                    _model.textController1!,
                                                    (val) =>
                                                        FFAppState().name = val,
                                                    '請輸入姓名',
                                                    isLandscape,
                                                    labelFontSize,
                                                    valueFontSize,
                                                    textFieldHeight),
                                                SizedBox(height: itemSpacing),
                                                _buildEditableInfoRow(
                                                    context,
                                                    '暱稱 :',
                                                    _model.textController2!,
                                                    (val) => FFAppState()
                                                        .nickname = val,
                                                    '請輸入暱稱',
                                                    isLandscape,
                                                    labelFontSize,
                                                    valueFontSize,
                                                    textFieldHeight),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0, 0, generalPadding, 0),
                                            child: CachedNetworkImage(
                                              imageUrl: FFAppState().avatar,
                                              width: avatarSize,
                                              height: avatarSize,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildInfoRow(
                                                    context,
                                                    '帳號 :',
                                                    FFAppState().accountnumber,
                                                    isLandscape,
                                                    labelFontSize,
                                                    valueFontSize,
                                                    readOnly: true),
                                                SizedBox(height: itemSpacing),
                                                _buildEditableInfoRow(
                                                    context,
                                                    '姓名 :',
                                                    _model.textController1!,
                                                    (val) =>
                                                        FFAppState().name = val,
                                                    '請輸入姓名',
                                                    isLandscape,
                                                    labelFontSize,
                                                    valueFontSize,
                                                    textFieldHeight),
                                                SizedBox(height: itemSpacing),
                                                _buildEditableInfoRow(
                                                    context,
                                                    '暱稱 :',
                                                    _model.textController2!,
                                                    (val) => FFAppState()
                                                        .nickname = val,
                                                    '請輸入暱稱',
                                                    isLandscape,
                                                    labelFontSize,
                                                    valueFontSize,
                                                    textFieldHeight),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                              ),

                              // Rest of the form fields - optimized for landscape mode with 2 columns
                              isLandscape
                                  ? _buildLandscapeFormLayout(
                                      context,
                                      labelFontSize,
                                      valueFontSize,
                                      itemSpacing,
                                      textFieldHeight,
                                      dropDownWidth,
                                      dropDownHeight)
                                  : _buildPortraitFormLayout(
                                      context,
                                      labelFontSize,
                                      valueFontSize,
                                      itemSpacing,
                                      textFieldHeight,
                                      dropDownWidth,
                                      dropDownHeight),

                              SizedBox(height: generalPadding * 1.5),

                              // Save Button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FFButtonWidget(
                                    onPressed: () async {
                                      await editData();
                                    },
                                    text: '儲存',
                                    options: FFButtonOptions(
                                      width: buttonWidth,
                                      height: buttonHeight,
                                      padding: EdgeInsetsDirectional.zero,
                                      iconPadding: EdgeInsetsDirectional.zero,
                                      color: Color(0xFFFFAC8F),
                                      textStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                              fontFamily: 'Poppins',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .black600,
                                              fontSize: buttonFontSize,
                                              fontWeight: FontWeight.bold),
                                      elevation: 2.0,
                                      borderSide: BorderSide(
                                        color: Colors.transparent,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          isLandscape ? 12.0 : 8.0),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                  height:
                                      generalPadding), // Ensure space for keyboard
                            ],
                          ),
                        ),
                ),
              ),

              // Bottom Navigation Bar
              BottomNavigation(currentPage: 'setting', isSubPage: true),
            ],
          ),
        ),
      ),
    );
  }

  // 橫向模式的表單佈局 - 雙列排列
  Widget _buildLandscapeFormLayout(
      BuildContext context,
      double labelFontSize,
      double valueFontSize,
      double itemSpacing,
      double textFieldHeight,
      double dropDownWidth,
      double dropDownHeight) {
    return Column(
      children: [
        // 將表單分為左右兩列，使用 Row 佈局
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左側列 - 基本信息、生日、年齡、性別、診斷、患側
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDatePickerRow(context, '生日 :', FFAppState().timepicker,
                      (date) {
                    if (date != null) {
                      setState(() {
                        _model.datePicked = date;
                        FFAppState().timepicker = _model.datePicked;
                      });
                    }
                  }, true, labelFontSize, valueFontSize),
                  SizedBox(height: itemSpacing),

                  if (FFAppState().timepicker != null)
                    _buildInfoRow(
                        context,
                        '年齡 :',
                        '${getAge(FFAppState().timepicker as DateTime)} 歲',
                        true,
                        labelFontSize,
                        valueFontSize),
                  SizedBox(height: itemSpacing),

                  _buildGenderPickerRow(context, '性別 :', FFAppState().gender,
                      (isFemale) {
                    setState(() {
                      if (isFemale) {
                        FFAppState().avatar = FFAppState().imagegirl;
                        FFAppState().gender = '女';
                      } else {
                        FFAppState().avatar = FFAppState().imageboy;
                        FFAppState().gender = '男';
                      }
                    });
                  }, true, labelFontSize, valueFontSize),
                  SizedBox(height: itemSpacing),

                  // 診斷與患側放在同一垂直列
                  _buildDropdownRow(
                      context,
                      '診斷 :',
                      _model.dropDownValueController1,
                      FFAppState().diagnosis,
                      ['左側出血性腦中風', '左側缺血性腦中風', '右側出血性腦中風', '右側缺血性腦中風'], (val) {
                    setState(() {
                      _model.dropDownValue1 = val;
                      FFAppState().diagnosis = _model.dropDownValue1!;
                    });
                  }, true, labelFontSize, valueFontSize, dropDownWidth,
                      dropDownHeight),
                  SizedBox(height: itemSpacing),

                  _buildDropdownRow(
                      context,
                      '患側 :',
                      _model.dropDownValueController2,
                      FFAppState().affectedside,
                      ['左側', '右側'], (val) {
                    setState(() {
                      _model.dropDownValue2 = val;
                      FFAppState().affectedside = _model.dropDownValue2!;
                    });
                  }, true, labelFontSize, valueFontSize, dropDownWidth,
                      dropDownHeight),
                ],
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.03), // 列間距
            // 右側列 - 聯絡資訊
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 聯絡電話、緊急聯絡人、緊急聯絡人電話、加入日期（只讀）放在同一垂直列
                  _buildEditableInfoRow(
                      context,
                      '聯絡電話:',
                      _model.textController3!,
                      (val) => FFAppState().phone = val,
                      '聯絡電話',
                      true,
                      labelFontSize,
                      valueFontSize,
                      textFieldHeight,
                      isPhoneNumber: true),
                  SizedBox(height: itemSpacing),

                  _buildEditableInfoRow(
                      context,
                      '緊急聯絡人:',
                      _model.textController4!,
                      (val) => FFAppState().urgenname = val,
                      '緊急聯絡人',
                      true,
                      labelFontSize,
                      valueFontSize,
                      textFieldHeight),
                  SizedBox(height: itemSpacing),

                  _buildEditableInfoRow(
                      context,
                      '緊急聯絡人電話:',
                      _model.textController5!,
                      (val) => FFAppState().nickphone = val,
                      '緊急聯絡人電話',
                      true,
                      labelFontSize,
                      valueFontSize,
                      textFieldHeight,
                      isPhoneNumber: true),
                  SizedBox(height: itemSpacing),

                  _buildInfoRow(
                      context,
                      '加入日期 :',
                      FFAppState().joindate != null
                          ? dateTimeFormat('yyyy/MM/dd', FFAppState().joindate!)
                          : '未設定',
                      true,
                      labelFontSize,
                      valueFontSize,
                      readOnly: true),
                ],
              ),
            ),
          ],
        ),
        // 移除底部項目 - 已經移動到右側列
      ],
    );
  }

  // 直向模式的表單佈局 - 單列排列
  Widget _buildPortraitFormLayout(
      BuildContext context,
      double labelFontSize,
      double valueFontSize,
      double itemSpacing,
      double textFieldHeight,
      double dropDownWidth,
      double dropDownHeight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDatePickerRow(context, '生日 :', FFAppState().timepicker, (date) {
          if (date != null) {
            setState(() {
              _model.datePicked = date;
              FFAppState().timepicker = _model.datePicked;
            });
          }
        }, false, labelFontSize, valueFontSize),
        SizedBox(height: itemSpacing),
        if (FFAppState().timepicker != null)
          _buildInfoRow(
              context,
              '年齡 :',
              '${getAge(FFAppState().timepicker as DateTime)} 歲',
              false,
              labelFontSize,
              valueFontSize),
        SizedBox(height: itemSpacing),
        _buildGenderPickerRow(context, '性別 :', FFAppState().gender, (isFemale) {
          setState(() {
            if (isFemale) {
              FFAppState().avatar = FFAppState().imagegirl;
              FFAppState().gender = '女';
            } else {
              FFAppState().avatar = FFAppState().imageboy;
              FFAppState().gender = '男';
            }
          });
        }, false, labelFontSize, valueFontSize),
        SizedBox(height: itemSpacing),
        _buildDropdownRow(
            context,
            '診斷 :',
            _model.dropDownValueController1,
            FFAppState().diagnosis,
            ['左側出血性腦中風', '左側缺血性腦中風', '右側出血性腦中風', '右側缺血性腦中風'], (val) {
          setState(() {
            _model.dropDownValue1 = val;
            FFAppState().diagnosis = _model.dropDownValue1!;
          });
        }, false, labelFontSize, valueFontSize, dropDownWidth, dropDownHeight),
        SizedBox(height: itemSpacing),
        _buildDropdownRow(context, '患側 :', _model.dropDownValueController2,
            FFAppState().affectedside, ['左側', '右側'], (val) {
          setState(() {
            _model.dropDownValue2 = val;
            FFAppState().affectedside = _model.dropDownValue2!;
          });
        }, false, labelFontSize, valueFontSize, dropDownWidth, dropDownHeight),
        SizedBox(height: itemSpacing),
        _buildEditableInfoRow(
            context,
            '聯絡電話:',
            _model.textController3!,
            (val) => FFAppState().phone = val,
            '聯絡電話',
            false,
            labelFontSize,
            valueFontSize,
            textFieldHeight,
            isPhoneNumber: true),
        SizedBox(height: itemSpacing),
        _buildEditableInfoRow(
            context,
            '緊急聯絡人:',
            _model.textController4!,
            (val) => FFAppState().urgenname = val,
            '緊急聯絡人',
            false,
            labelFontSize,
            valueFontSize,
            textFieldHeight),
        SizedBox(height: itemSpacing),
        _buildEditableInfoRow(
            context,
            '緊急聯絡人電話:',
            _model.textController5!,
            (val) => FFAppState().nickphone = val,
            '緊急聯絡人電話',
            false,
            labelFontSize,
            valueFontSize,
            textFieldHeight,
            isPhoneNumber: true),
        SizedBox(height: itemSpacing),
        _buildInfoRow(
            context,
            '加入日期 :',
            FFAppState().joindate != null
                ? dateTimeFormat('yyyy/MM/dd', FFAppState().joindate!)
                : '未設定',
            false,
            labelFontSize,
            valueFontSize,
            readOnly: true),
      ],
    );
  }

  // Helper widget for non-editable info rows
  Widget _buildInfoRow(BuildContext context, String label, String value,
      bool isLandscape, double labelFontSize, double valueFontSize,
      {bool readOnly = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final labelWidth = isLandscape ? screenWidth * 0.1 : screenWidth * 0.22;

    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Poppins',
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        SizedBox(width: screenWidth * (isLandscape ? 0.01 : 0.02)),
        Expanded(
          child: AutoSizeText(
            value,
            textAlign: readOnly ? TextAlign.start : TextAlign.center,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Poppins',
                  fontSize: valueFontSize,
                ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  // Helper widget for editable info rows (TextFormFields)
  Widget _buildEditableInfoRow(
      BuildContext context,
      String label,
      TextEditingController controller,
      Function(String) onSubmitted,
      String hintText,
      bool isLandscape,
      double labelFontSize,
      double valueFontSize,
      double fieldHeight,
      {bool isPhoneNumber = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final labelWidth = isLandscape ? screenWidth * 0.1 : screenWidth * 0.22;

    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Poppins',
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        SizedBox(width: screenWidth * (isLandscape ? 0.01 : 0.02)),
        Expanded(
          child: Container(
            height: fieldHeight,
            child: TextFormField(
              controller: controller,
              onChanged: (_) => EasyDebounce.debounce(
                'textController_${label.hashCode}', // Unique debounce ID
                Duration(milliseconds: 1000), // Reduced debounce time
                () => setState(() {}),
              ),
              onFieldSubmitted: (val) async {
                setState(() {
                  onSubmitted(val);
                });
              },
              obscureText: false,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'Poppins',
                      fontSize: valueFontSize * 0.9,
                    ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0x00000000), width: 1.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).primary, width: 1.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                errorBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).error, width: 1.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedErrorBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).error, width: 1.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: FlutterFlowTheme.of(context).primaryBackground,
                contentPadding: EdgeInsetsDirectional.fromSTEB(
                    12.0, 0, 12.0, 0), // Adjusted padding
                suffixIcon: controller.text.isNotEmpty
                    ? InkWell(
                        onTap: () async {
                          controller.clear();
                          setState(() {});
                        },
                        child: Icon(Icons.clear,
                            color: Color(0xFF757575),
                            size: valueFontSize * 0.8),
                      )
                    : null,
              ),
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Poppins',
                    fontSize: valueFontSize,
                  ),
              textAlign: TextAlign.start,
              keyboardType:
                  isPhoneNumber ? TextInputType.phone : TextInputType.text,
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for DatePicker rows
  Widget _buildDatePickerRow(
      BuildContext context,
      String label,
      DateTime? currentValue,
      Function(DateTime?) onDatePicked,
      bool isLandscape,
      double labelFontSize,
      double valueFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final labelWidth = isLandscape ? screenWidth * 0.1 : screenWidth * 0.22;

    return InkWell(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: currentValue ?? getCurrentTimestamp,
          firstDate: DateTime(1900),
          lastDate: DateTime(2050),
          builder: (context, child) {
            // Optional: Theming the date picker
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: FlutterFlowTheme.of(context)
                      .primary, // header background color
                  onPrimary: Colors.white, // header text color
                  onSurface: FlutterFlowTheme.of(context)
                      .primaryText, // body text color
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: FlutterFlowTheme.of(context)
                        .primary, // button text color
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        onDatePicked(pickedDate);
      },
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Poppins',
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              currentValue != null
                  ? dateTimeFormat('yyyy/MM/dd', currentValue)
                  : '請選擇日期',
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Poppins',
                    fontSize: valueFontSize,
                    color: currentValue != null
                        ? FlutterFlowTheme.of(context).primaryText
                        : FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 10.0, 0.0),
            child: Icon(Icons.arrow_forward_ios,
                color: Colors.black, size: valueFontSize),
          ),
        ],
      ),
    );
  }

  // Helper for Gender Picker
  Widget _buildGenderPickerRow(
      BuildContext context,
      String label,
      String currentValue,
      Function(bool) onGenderSelected,
      bool isLandscape,
      double labelFontSize,
      double valueFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final labelWidth = isLandscape ? screenWidth * 0.1 : screenWidth * 0.22;

    return InkWell(
      onTap: () async {
        bool? confirmDialogResponse = await showDialog<bool>(
          context: context,
          builder: (alertDialogContext) {
            return AlertDialog(
              title: Text('請選擇性別',
                  style: TextStyle(fontSize: labelFontSize * 0.9)),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(alertDialogContext, false), // Male
                  child: Text('男', style: TextStyle(fontSize: valueFontSize)),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(alertDialogContext, true), // Female
                  child: Text('女', style: TextStyle(fontSize: valueFontSize)),
                ),
              ],
            );
          },
        );
        if (confirmDialogResponse != null) {
          onGenderSelected(confirmDialogResponse);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Poppins',
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              currentValue.isNotEmpty ? currentValue : '請選擇性別',
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Poppins',
                    fontSize: valueFontSize,
                    color: currentValue.isNotEmpty
                        ? FlutterFlowTheme.of(context).primaryText
                        : FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 10.0, 0.0),
            child: Icon(Icons.arrow_forward_ios,
                color: Colors.black, size: valueFontSize),
          ),
        ],
      ),
    );
  }

  // Helper widget for Dropdown rows
  Widget _buildDropdownRow(
      BuildContext context,
      String label,
      FormFieldController<String>? controller,
      String? currentValue,
      List<String> options,
      Function(String?) onChanged,
      bool isLandscape,
      double labelFontSize,
      double valueFontSize,
      double dropdownWidth,
      double dropdownHeight) {
    final screenWidth = MediaQuery.of(context).size.width;
    final labelWidth = isLandscape ? screenWidth * 0.1 : screenWidth * 0.22;

    // 確保控制器有正確的當前值
    if (controller != null && controller.value != currentValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.value = currentValue;
      });
    }

    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Poppins',
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        SizedBox(width: screenWidth * (isLandscape ? 0.01 : 0.02)),
        Expanded(
          child: FlutterFlowDropDown<String>(
            controller: controller ?? FormFieldController<String>(currentValue),
            options: options,
            onChanged: (val) async {
              onChanged(val);
              setState(() {});
            },
            width: dropdownWidth, // Use responsive width
            height: dropdownHeight, // Use responsive height
            textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Poppins',
                  color: Colors.black,
                  fontSize: valueFontSize,
                ),
            hintText: ' 請做選擇',
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: FlutterFlowTheme.of(context).secondaryText,
                size: valueFontSize * 1.2),
            fillColor: FlutterFlowTheme.of(context).primaryBackground,
            elevation: 2.0,
            borderColor: FlutterFlowTheme.of(context).alternate,
            borderWidth: 1.0,
            borderRadius: 8.0,
            margin:
                EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0), // Adjusted margin
            hidesUnderline: true,
            isSearchable: false,
          ),
        ),
      ],
    );
  }
}
