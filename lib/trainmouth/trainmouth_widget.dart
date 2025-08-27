import 'dart:convert';
import '../main.dart';
import '../vision_detector_views/label_detector_view/face_class.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'trainmouth_model.dart';
export 'trainmouth_model.dart';
import '../vision_detector_views/label_detector_view/face_video.dart';

int Face_Detect_Number = 0;

class TrainmouthWidget extends StatefulWidget {
  const TrainmouthWidget({Key? key}) : super(key: key);

  @override
  _TrainmouthWidgetState createState() => _TrainmouthWidgetState();
}

class _TrainmouthWidgetState extends State<TrainmouthWidget> {
  late TrainmouthModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();

  var gettime = DateTime.now(); //獲取按下去的時間
  var gettime1; //轉換輸出型態月日年轉年月日

  inputtime() async {
    //測試動作有無反應
    try {
      if (!mounted) return;
      await Navigator.push(
          context, MaterialPageRoute(builder: (context) => FaceVideoApp()));
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
    _model = createModel(context, () => TrainmouthModel());
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

    gettime1 = dateTimeFormat('yyyy-M-d', gettime); //轉換輸出型態月日年轉年月日

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
                        'assets/images/15.png', // Placeholder for mouth training icon
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
                        '口腔訓練',
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
                                      imagePath: 'assets/images/57.png',
                                      title: '抿唇動作',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        setState(() {
                                          Face_Detect_Number = 6; //抿唇動作
                                          FFAppState().mouth = '抿唇動作';
                                        });
                                        inputtime();
                                      },
                                    ),
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/44.png',
                                      title: '臉頰微笑',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        setState(() {
                                          Face_Detect_Number = 1; //微笑動作
                                          FFAppState().mouth = '臉頰微笑';
                                        });
                                        inputtime();
                                      },
                                    ),
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/46.png',
                                      title: '彈舌式',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        setState(() {
                                          Face_Detect_Number = 5;
                                          FFAppState().mouth = '彈舌式';
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
                                      imagePath: 'assets/images/53.png',
                                      title: '下巴運動',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        setState(() {
                                          Face_Detect_Number = 8;
                                          FFAppState().mouth = '下巴運動';
                                        });
                                        inputtime();
                                      },
                                    ),
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/55.png',
                                      title: '嘟嘴式',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        setState(() {
                                          Face_Detect_Number = 3;
                                          FFAppState().mouth = '嘟嘴式';
                                        });
                                        inputtime();
                                      },
                                    ),
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/yawning.png',
                                      title: '張嘴說阿',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        setState(() {
                                          Face_Detect_Number = 4;
                                          FFAppState().mouth = '張嘴說阿';
                                        });
                                        inputtime();
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                // 第三排 (3個訓練)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/54.png',
                                      title: '頭頸側彎',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        setState(() {
                                          Face_Detect_Number = 7;
                                          FFAppState().mouth = '頭頸側彎';
                                        });
                                        inputtime();
                                      },
                                    ),
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/45.png',
                                      title: '吐舌頭式',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        setState(() {
                                          Face_Detect_Number = 2;
                                          FFAppState().mouth = '吐舌頭式';
                                        });
                                        inputtime();
                                      },
                                    ),
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/56.png',
                                      title: '發音練習',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        setState(() {
                                          Face_Detect_Number = 9;
                                          FFAppState().mouth = '發音練習';
                                        });
                                        inputtime();
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                // 第四排 (3個訓練)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/59.png',
                                      title: '頭部轉向',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        setState(() {
                                          Face_Detect_Number = 10;
                                          FFAppState().mouth = '頭部轉向';
                                        });
                                        inputtime();
                                      },
                                    ),
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath:
                                          'assets/images/28.png', // Placeholder, might need a specific icon
                                      title: '肩部上下',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        setState(() {
                                          Face_Detect_Number = 11;
                                          FFAppState().mouth = '肩部上下';
                                        });
                                        inputtime();
                                      },
                                    ),
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath:
                                          'assets/images/salivary-glands.png',
                                      title: '唾液腺',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        setState(() {
                                          Face_Detect_Number = 12;
                                          FFAppState().mouth = '唾液腺';
                                        });
                                        inputtime();
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                // 第五排 (2個訓練)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath: 'assets/images/upset.png',
                                      title: '臉頰鼓起',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        setState(() {
                                          Face_Detect_Number = 13;
                                          FFAppState().mouth = '臉頰鼓起';
                                        });
                                        inputtime();
                                      },
                                    ),
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath:
                                          'assets/images/tongue-depressor.png',
                                      title: '舌頂舌板',
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () async {
                                        setState(() {
                                          Face_Detect_Number = 14;
                                          FFAppState().mouth = '抿壓舌板';
                                        });
                                        inputtime();
                                      },
                                    ),
                                    // Empty container to balance the row if only 2 items
                                    _buildExerciseItem(
                                      context: context,
                                      imagePath:
                                          'assets/images/transparent.png', // Path to a transparent image
                                      title: '', // Empty title
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      onTap: () {}, // No action on tap
                                      isPlaceholder:
                                          true, // Flag to indicate this is a placeholder
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
                                              setState(() {
                                                Face_Detect_Number = 6; //抿唇動作
                                                FFAppState().mouth = '抿唇動作';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/57.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          Text(
                                            '抿唇動作',
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
                                              setState(() {
                                                Face_Detect_Number = 1; //微笑動作
                                                FFAppState().mouth = '臉頰微笑';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/44.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '臉頰微笑',
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
                                              setState(() {
                                                Face_Detect_Number = 5;
                                                FFAppState().mouth = '彈舌式';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/46.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '彈舌式',
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
                                              setState(() {
                                                Face_Detect_Number = 8;
                                                FFAppState().mouth = '下巴運動';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/53.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '下巴運動',
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
                                              setState(() {
                                                Face_Detect_Number = 3;
                                                FFAppState().mouth = '嘟嘴式';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/55.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '嘟嘴式',
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
                                              setState(() {
                                                Face_Detect_Number = 4;
                                                FFAppState().mouth = '張嘴說阿';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/yawning.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '張嘴說阿',
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
                                              setState(() {
                                                Face_Detect_Number = 7;
                                                FFAppState().mouth = '頭頸側彎';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/54.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '頭頸側彎',
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
                                              setState(() {
                                                Face_Detect_Number = 2;
                                                FFAppState().mouth = '吐舌頭式';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/45.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '吐舌頭式',
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
                                              setState(() {
                                                Face_Detect_Number = 9;
                                                FFAppState().mouth = '發音練習';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/56.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '發音練習',
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
                                              setState(() {
                                                Face_Detect_Number = 10;
                                                FFAppState().mouth = '頭部轉向';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/59.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '頭部轉向',
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
                                              setState(() {
                                                Face_Detect_Number = 11;
                                                FFAppState().mouth = '肩部上下';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/28.png', // Placeholder, might need a specific icon
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '肩部上下',
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
                                              setState(() {
                                                Face_Detect_Number = 12;
                                                FFAppState().mouth = '唾液腺';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/salivary-glands.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '唾液腺',
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
                                              setState(() {
                                                Face_Detect_Number = 13;
                                                FFAppState().mouth = '臉頰鼓起';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/upset.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '臉頰鼓起',
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
                                              setState(() {
                                                Face_Detect_Number = 14;
                                                FFAppState().mouth = '舌頂舌板';
                                              });
                                              inputtime();
                                            },
                                            child: Image.asset(
                                              'assets/images/tongue-depressor.png',
                                              width: screenSize.width * 0.35,
                                              height: screenSize.width * 0.35,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Text(
                                            '抿壓舌板',
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
              BottomNavigation(currentPage: 'trainmouth', isSubPage: true),
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
  bool isPlaceholder =
      false, // Added isPlaceholder parameter with a default value
}) {
  final screenWidth = screenSize.width;
  final screenHeight = screenSize.height;

  final imageSize = isLandscape
      ? screenHeight * 0.2 // Adjusted for potentially more items
      : screenWidth * 0.35;

  final fontSize = isLandscape
      ? screenHeight * 0.04 // Adjusted for potentially more items
      : screenWidth * 0.08;

  if (isPlaceholder) {
    // Return a transparent container with the same dimensions as a regular item
    return Container(
      width:
          imageSize, // Ensure the placeholder has a defined width to affect layout
      height: imageSize +
          (screenHeight * 0.01) +
          fontSize, // Approximate height of image + sizedbox + text
      color: Colors.transparent,
    );
  }

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
