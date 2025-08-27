import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'trainlowerbody2_model.dart';
export 'trainlowerbody2_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/main.dart';
import '../vision_detector_views/pose_transform.dart';
import '../vision_detector_views/pose_video.dart';
import '/flutter_flow/bottom_navigation.dart';

class Trainlowerbody2Widget extends StatefulWidget {
  const Trainlowerbody2Widget({Key? key}) : super(key: key);

  @override
  _Trainlowerbody2WidgetState createState() => _Trainlowerbody2WidgetState();
}

class _Trainlowerbody2WidgetState extends State<Trainlowerbody2Widget> {
  late Trainlowerbody2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();

  var gettime = DateTime.now(); //獲取按下去的時間
  var gettime1; //轉換輸出型態月日年轉年月日
  /*inputtime()async{                                                           //此函式是鎖一天只能做一個動作並傳遞後端
    var url = Uri.parse(ip+"inputtimeDOWN.php");
    final responce = await http.post(url,body: {
      "account" : FFAppState().accountnumber,
      "degree":"進階",
      "parts":"下肢",
      "time": gettime1.toString(),
      "action": FFAppState().traindown,//動作
    });
    if (responce.statusCode == 200) {
      var data = json.decode(responce.body); //將json解碼為陣列形式
      print(data["action"]);
      print(data["time"]);
      print(gettime1=dateTimeFormat('yyyy-M-d', gettime));//轉換輸出型態月日年轉年月日
      if("沒時間"==data["time"]){
        if("有訓練"==data["action"]||"有時間"==data["time"]){

        }
        else{
          Navigator.push(context,
            MaterialPageRoute(builder: (context)=>VideoApp()),
          );
        }
      }
      else if(data["times"]=="1次"&&"有時間"==data["time"]){
        if(data["timeaction"]=="對"){
          Navigator.push(context,
            MaterialPageRoute(builder: (context)=>VideoApp()),
          );
        }
      }
      else if(data["times"]=="2次"){

      }
    }
  }*/

  inputtime() async {
    //此函式為代替方案，不限制一天動作，可以一職測試 測試完請刪掉
    try {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VideoApp()),
      );
    } catch (e) {
      print('導航錯誤: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法打開訓練界面，請稍後重試')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Trainlowerbody2Model());
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
    gettime1 = dateTimeFormat('yyyy-M-d', gettime);
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_unfocusNode),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFF90BDF9),
        body: SafeArea(
          top: true,
          bottom: false, // 關閉底部安全區域，讓導航欄可以貼合底部
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 固定標題區域
              Container(
                width: double.infinity,
                height: isLandscape
                    ? screenHeight * 0.15
                    : screenHeight * 0.1, // 根據方向設置不同的高度比例
                color: Color(0xFF90BDF9),
                padding: EdgeInsets.symmetric(
                    vertical: isLandscape
                        ? screenHeight * 0.01
                        : screenHeight * 0.01),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          screenWidth * 0.03, 0.0, 0.0, 0.0),
                      child: Image.asset(
                        'assets/images/14.png',
                        width: isLandscape
                            ? screenHeight * 0.1
                            : screenWidth * 0.15,
                        height: isLandscape
                            ? screenHeight * 0.1
                            : screenWidth * 0.15,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          screenWidth * 0.04, 0.0, 0.0, 0.0),
                      child: Text(
                        '進階訓練',
                        textAlign: TextAlign.start,
                        style:
                            FlutterFlowTheme.of(context).displaySmall.override(
                                  fontFamily: 'Poppins',
                                  fontSize: isLandscape
                                      ? screenHeight * 0.07 // 橫向時使用螢幕高度比例
                                      : screenWidth * 0.08, // 直向時使用螢幕寬度比例
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ],
                ),
              ),

              // 中間內容區域 (可滾動)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    child: isLandscape
                        // 橫向模式
                        ? Padding(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            child: Column(
                              children: [
                                // 第一排 (3個訓練)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/34.png',
                                      title: '側抬腳式',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        if (FFAppState().affectedside == null)
                                          return;
                                        else if (FFAppState().affectedside ==
                                            "右側")
                                          global.posenumber = 18;
                                        else
                                          global.posenumber = 42;

                                        setState(() {
                                          FFAppState().traindown = '側抬腳式';
                                        });
                                        inputtime();
                                      },
                                    ),
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/40.png',
                                      title: '站姿抬腳',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        if (FFAppState().affectedside == null)
                                          return;
                                        else if (FFAppState().affectedside ==
                                            "右側")
                                          global.posenumber = 19;
                                        else
                                          global.posenumber = 43;

                                        setState(() {
                                          FFAppState().traindown = '站姿抬腳';
                                        });
                                        inputtime();
                                      },
                                    ),
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/41.png',
                                      title: '跨步動作',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        if (FFAppState().affectedside == null)
                                          return;
                                        else if (FFAppState().affectedside ==
                                            "右側")
                                          global.posenumber = 20;
                                        else
                                          global.posenumber = 44;

                                        setState(() {
                                          FFAppState().traindown = '跨步動作';
                                        });
                                        inputtime();
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                // 第二排 (3個訓練)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/37.png',
                                      title: '站姿膝彎曲',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        if (FFAppState().affectedside == null)
                                          return;
                                        else if (FFAppState().affectedside ==
                                            "右側")
                                          global.posenumber = 21;
                                        else
                                          global.posenumber = 45;

                                        setState(() {
                                          FFAppState().traindown = '站姿膝彎曲';
                                        });
                                        inputtime();
                                      },
                                    ),
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/42.png',
                                      title: '坐姿動態',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        if (FFAppState().affectedside == null)
                                          return;
                                        else if (FFAppState().affectedside ==
                                            "右側")
                                          global.posenumber = 22;
                                        else
                                          global.posenumber = 46;

                                        setState(() {
                                          FFAppState().traindown = '坐姿動態';
                                        });
                                        inputtime();
                                      },
                                    ),
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/52.png',
                                      title: '坐姿平衡',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        if (FFAppState().affectedside == null)
                                          return;
                                        else if (FFAppState().affectedside ==
                                            "右側")
                                          global.posenumber = 23;
                                        else
                                          global.posenumber = 47;

                                        setState(() {
                                          FFAppState().traindown = '坐姿平衡';
                                        });
                                        inputtime();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        // 直向模式 (保持原始布局)
                        : Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              if (FFAppState().affectedside ==
                                                  null)
                                                return;
                                              else if (FFAppState()
                                                      .affectedside ==
                                                  "右側")
                                                global.posenumber = 18;
                                              else
                                                global.posenumber = 42;

                                              setState(() {
                                                FFAppState().traindown = '側抬腳式';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/34.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '側抬腳式',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  fontSize:
                                                      screenSize.width * 0.08,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              if (FFAppState().affectedside ==
                                                  null)
                                                return;
                                              else if (FFAppState()
                                                      .affectedside ==
                                                  "右側")
                                                global.posenumber = 19;
                                              else
                                                global.posenumber = 43;

                                              setState(() {
                                                FFAppState().traindown = '站姿抬腳';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/40.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '站姿抬腳',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  fontSize:
                                                      screenSize.width * 0.08,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              if (FFAppState().affectedside ==
                                                  null)
                                                return;
                                              else if (FFAppState()
                                                      .affectedside ==
                                                  "右側")
                                                global.posenumber = 20;
                                              else
                                                global.posenumber = 44;

                                              setState(() {
                                                FFAppState().traindown = '跨步動作';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/41.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '跨步動作',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  fontSize:
                                                      screenSize.width * 0.08,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              if (FFAppState().affectedside ==
                                                  null)
                                                return;
                                              else if (FFAppState()
                                                      .affectedside ==
                                                  "右側")
                                                global.posenumber = 21;
                                              else
                                                global.posenumber = 45;

                                              setState(() {
                                                FFAppState().traindown =
                                                    '站姿膝彎曲';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/37.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '站姿膝彎曲',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  fontSize:
                                                      screenSize.width * 0.08,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              if (FFAppState().affectedside ==
                                                  null)
                                                return;
                                              else if (FFAppState()
                                                      .affectedside ==
                                                  "右側")
                                                global.posenumber = 22;
                                              else
                                                global.posenumber = 46;

                                              setState(() {
                                                FFAppState().traindown = '坐姿動態';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/42.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '坐姿動態',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  fontSize:
                                                      screenSize.width * 0.08,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              if (FFAppState().affectedside ==
                                                  null)
                                                return;
                                              else if (FFAppState()
                                                      .affectedside ==
                                                  "右側")
                                                global.posenumber = 23;
                                              else
                                                global.posenumber = 47;

                                              setState(() {
                                                FFAppState().traindown = '坐姿平衡';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/52.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '坐姿平衡',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  fontSize:
                                                      screenSize.width * 0.08,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              // 底部固定導航欄
              BottomNavigation(currentPage: 'trainlowerbody2', isSubPage: true),
            ],
          ),
        ),
      ),
    );
  }
}

// 訓練項目組件 (橫向模式專用)
Widget _buildExerciseItem({
  required BuildContext context,
  required String imagePath,
  required String title,
  required Size screenSize,
  required bool isLandscape,
  required VoidCallback onTap,
}) {
  final screenWidth = screenSize.width;
  final screenHeight = screenSize.height;

  final imageSize = isLandscape ? screenHeight * 0.2 : screenWidth * 0.35;

  final fontSize = isLandscape ? screenHeight * 0.05 : screenWidth * 0.08;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Image.asset(
          imagePath,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.fill,
        ),
      ),
      SizedBox(height: screenHeight * 0.01),
      Text(
        title,
        style: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'Poppins',
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
      ),
    ],
  );
}
