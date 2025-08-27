import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/bottom_navigation.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'about_model.dart';
export 'about_model.dart';
import 'package:go_router/go_router.dart';

class AboutWidget extends StatefulWidget {
  const AboutWidget({Key? key}) : super(key: key);

  @override
  _AboutWidgetState createState() => _AboutWidgetState();
}

class _AboutWidgetState extends State<AboutWidget> {
  late AboutModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AboutModel());
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

    final titleFontSize =
        isLandscape ? screenHeight * 0.07 : screenWidth * 0.08;
    final contentFontSize =
        isLandscape ? screenHeight * 0.04 : screenWidth * 0.05;
    final smallContentFontSize =
        isLandscape ? screenHeight * 0.035 : screenWidth * 0.04;

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_unfocusNode),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFF90BDF9), // Consistent background color
        body: SafeArea(
          top: true,
          bottom: false, // 關閉底部安全區域，讓導航欄可以貼合底部
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fixed Header Area
              Container(
                width: double.infinity,
                height: isLandscape ? screenHeight * 0.15 : screenHeight * 0.1,
                color: Color(0xFF90BDF9),
                padding: EdgeInsets.symmetric(
                    vertical: isLandscape
                        ? screenHeight * 0.01
                        : screenHeight * 0.01),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '關於',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).displaySmall.override(
                            fontFamily: 'Poppins',
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              // Scrollable Content Area
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(
                        isLandscape ? screenWidth * 0.03 : screenWidth * 0.04),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4.0,
                            color: Color(0x5B000000),
                            offset: Offset(0.0, -2.0),
                          )
                        ],
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '發展及合作單位:',
                              style: FlutterFlowTheme.of(context)
                                  .displaySmall
                                  .override(
                                    fontFamily: 'Poppins',
                                    fontSize: contentFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Color(0xFFE0E7F0),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4.0,
                                    color: Color(0x33000000),
                                    offset: Offset(3.0, 10.0),
                                  )
                                ],
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '高雄醫學大學',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Poppins',
                                          fontSize: smallContentFontSize,
                                        ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '花蓮慈濟醫院',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Poppins',
                                          fontSize: smallContentFontSize,
                                        ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '國立高雄科技大學',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Poppins',
                                          fontSize: smallContentFontSize,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'APP 使用方式:',
                              style: FlutterFlowTheme.of(context)
                                  .displaySmall
                                  .override(
                                    fontFamily: 'Poppins',
                                    fontSize: contentFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Color(0xFFE0E7F0),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4.0,
                                    color: Color(0x33000000),
                                    offset: Offset(3.0, 10.0),
                                  )
                                ],
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Text(
                                '暫定',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Poppins',
                                      fontSize: smallContentFontSize,
                                    ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '最後更新時間:',
                              style: FlutterFlowTheme.of(context)
                                  .displaySmall
                                  .override(
                                    fontFamily: 'Poppins',
                                    fontSize: contentFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Color(0xFFE0E7F0),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4.0,
                                    color: Color(0x33000000),
                                    offset: Offset(3.0, 10.0),
                                  )
                                ],
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Text(
                                '2025/07/05',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Poppins',
                                      fontSize: smallContentFontSize,
                                    ),
                              ),
                            ),
                            SizedBox(height: 20),
                            Center(
                              child: Container(
                                width: isLandscape
                                    ? screenWidth * 0.4
                                    : screenWidth * 0.6,
                                height: isLandscape
                                    ? screenHeight * 0.1
                                    : screenHeight * 0.06,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await launchURL(
                                        'https://drive.google.com/drive/folders/1Suaj2T_KFVLwX32sacGBKUb-evTJcy1p?usp=drive_link');
                                  },
                                  child: Text(
                                    '醫療行為參考資料請按這',
                                    style: TextStyle(
                                        fontSize: smallContentFontSize,
                                        color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Color(0xFF6EBAFF), // Button color
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      textStyle: TextStyle(
                                        fontSize: smallContentFontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0))),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Fixed Bottom Navigation Bar
              BottomNavigation(currentPage: 'about'),
            ],
          ),
        ),
      ),
    );
  }
}
