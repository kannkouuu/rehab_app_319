import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'train_model.dart';
export 'train_model.dart';
import '/rsst_test/rsst_intro_page.dart';

class TrainWidget extends StatefulWidget {
  const TrainWidget({Key? key}) : super(key: key);

  @override
  _TrainWidgetState createState() => _TrainWidgetState();
}

class _TrainWidgetState extends State<TrainWidget> {
  late TrainModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TrainModel());
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

    // 計算自適應字體大小和按鈕大小
    final titleFontSize =
        isLandscape ? screenHeight * 0.07 : screenWidth * 0.08;
    final buttonTextFontSize =
        isLandscape ? screenHeight * 0.05 : screenWidth * 0.07;
    final buttonHeight =
        isLandscape ? screenHeight * 0.20 : screenHeight * 0.12;
    final buttonImageSize =
        isLandscape ? screenHeight * 0.1 : screenWidth * 0.12;
    final mainButtonPadding =
        isLandscape ? screenHeight * 0.02 : screenHeight * 0.02;

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
                height: isLandscape ? screenHeight * 0.15 : screenHeight * 0.1,
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
                        'assets/images/22.png',
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
                        '復健訓練',
                        textAlign: TextAlign.start,
                        style:
                            FlutterFlowTheme.of(context).displaySmall.override(
                                  fontFamily: 'Poppins',
                                  fontSize: titleFontSize,
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
                  child: Padding(
                    padding: EdgeInsets.all(
                        isLandscape ? screenWidth * 0.05 : screenWidth * 0.03),
                    child: isLandscape
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildTrainingButton(
                                      context: context,
                                      title: '上肢訓練',
                                      imagePath: 'assets/images/13.png',
                                      onTap: () =>
                                          context.pushNamed('trainupperbody'),
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      buttonHeight: buttonHeight,
                                      buttonTextFontSize: buttonTextFontSize,
                                      buttonImageSize: buttonImageSize,
                                      paddingBottom: mainButtonPadding,
                                    ),
                                    _buildTrainingButton(
                                      context: context,
                                      title: '口腔訓練',
                                      imagePath: 'assets/images/15.png',
                                      onTap: () =>
                                          context.pushNamed('trainmouth'),
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      buttonHeight: buttonHeight,
                                      buttonTextFontSize: buttonTextFontSize,
                                      buttonImageSize: buttonImageSize,
                                      paddingBottom:
                                          0, // No padding for the last button in the column
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  width: screenWidth *
                                      0.05), // Space between columns
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildTrainingButton(
                                      context: context,
                                      title: '下肢訓練',
                                      imagePath: 'assets/images/14.png',
                                      onTap: () =>
                                          context.pushNamed('trainlowerbody'),
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      buttonHeight: buttonHeight,
                                      buttonTextFontSize: buttonTextFontSize,
                                      buttonImageSize: buttonImageSize,
                                      paddingBottom: mainButtonPadding,
                                    ),
                                    _buildTrainingButton(
                                      context: context,
                                      title: '復健成效測驗',
                                      imagePath:
                                          'assets/images/15.png', // Consider a different icon for tests
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RsstIntroPage(),
                                        ),
                                      ),
                                      screenSize: screenSize,
                                      isLandscape: true,
                                      buttonHeight: buttonHeight,
                                      buttonTextFontSize: buttonTextFontSize,
                                      buttonImageSize: buttonImageSize,
                                      paddingBottom:
                                          0, // No padding for the last button in the column
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTrainingButton(
                                context: context,
                                title: '上肢訓練',
                                imagePath: 'assets/images/13.png',
                                onTap: () =>
                                    context.pushNamed('trainupperbody'),
                                screenSize: screenSize,
                                isLandscape: false,
                                buttonHeight: buttonHeight,
                                buttonTextFontSize: buttonTextFontSize,
                                buttonImageSize: buttonImageSize,
                                paddingBottom: mainButtonPadding,
                              ),
                              _buildTrainingButton(
                                context: context,
                                title: '下肢訓練',
                                imagePath: 'assets/images/14.png',
                                onTap: () =>
                                    context.pushNamed('trainlowerbody'),
                                screenSize: screenSize,
                                isLandscape: false,
                                buttonHeight: buttonHeight,
                                buttonTextFontSize: buttonTextFontSize,
                                buttonImageSize: buttonImageSize,
                                paddingBottom: mainButtonPadding,
                              ),
                              _buildTrainingButton(
                                context: context,
                                title: '口腔訓練',
                                imagePath: 'assets/images/15.png',
                                onTap: () => context.pushNamed('trainmouth'),
                                screenSize: screenSize,
                                isLandscape: false,
                                buttonHeight: buttonHeight,
                                buttonTextFontSize: buttonTextFontSize,
                                buttonImageSize: buttonImageSize,
                                paddingBottom: mainButtonPadding,
                              ),
                              _buildTrainingButton(
                                context: context,
                                title: '復健成效測驗',
                                imagePath:
                                    'assets/images/15.png', // Consider a different icon for tests
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RsstIntroPage(),
                                  ),
                                ),
                                screenSize: screenSize,
                                isLandscape: false,
                                buttonHeight: buttonHeight,
                                buttonTextFontSize: buttonTextFontSize,
                                buttonImageSize: buttonImageSize,
                                paddingBottom:
                                    0, // No padding for the last button
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              // 底部固定導航欄
              BottomNavigation(currentPage: 'train', isSubPage: true),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildTrainingButton({
  required BuildContext context,
  required String title,
  required String imagePath,
  required VoidCallback onTap,
  required Size screenSize,
  required bool isLandscape,
  required double buttonHeight,
  required double buttonTextFontSize,
  required double buttonImageSize,
  required double paddingBottom,
}) {
  final screenWidth = screenSize.width;
  return Padding(
    padding: EdgeInsets.only(bottom: paddingBottom),
    child: Container(
      width: isLandscape ? double.infinity : screenWidth * 0.9,
      height: buttonHeight,
      decoration: BoxDecoration(
        color: Color(0xFFF4DB60),
        boxShadow: [
          BoxShadow(
            blurRadius: 4.0,
            color: Color(0x33000000),
            offset: Offset(5.0, 15.0),
          )
        ],
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal:
                  isLandscape ? screenSize.width * 0.02 : screenWidth * 0.05),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                imagePath,
                width: buttonImageSize,
                height: buttonImageSize,
                fit: BoxFit.contain,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.left,
                  style: FlutterFlowTheme.of(context).displaySmall.override(
                        fontFamily: 'Poppins',
                        color: Color(0xFFC50D1C),
                        fontSize: buttonTextFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
