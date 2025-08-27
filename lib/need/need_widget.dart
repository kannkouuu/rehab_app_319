import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'need_model.dart';
export 'need_model.dart';
import 'package:audioplayers/audioplayers.dart'; //播放音檔

class NeedWidget extends StatefulWidget {
  const NeedWidget({Key? key}) : super(key: key);

  @override
  _NeedWidgetState createState() => _NeedWidgetState();
}

class _NeedWidgetState extends State<NeedWidget> {
  late NeedModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();
  final AudioCache player = AudioCache();
  final AudioPlayer _audioPlayer = AudioPlayer(); //播放音檔

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NeedModel());
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_unfocusNode),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFFFFC1A1),
        body: SafeArea(
          top: true,
          bottom: false, // 關閉底部安全區域，讓導航欄可以貼合底部
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 頂部標題區域
              _buildPageHeader(context, '需求表達', 'assets/images/00.png'),

              // 中間內容區域 (可滾動)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    child: _buildGridLayout(context, screenSize, isLandscape),
                  ),
                ),
              ),

              // 底部導航欄
              BottomNavigation(currentPage: 'need', isSubPage: true),
            ],
          ),
        ),
      ),
    );
  }

  // 需求表達網格佈局
  Widget _buildGridLayout(
      BuildContext context, Size screenSize, bool isLandscape) {
    // 根據方向調整每行顯示的項目數
    final crossAxisCount = isLandscape ? 4 : 2;
    final childAspectRatio = isLandscape ? 0.8 : 0.9;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.03,
          vertical: screenSize.height * 0.02),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: screenSize.width * 0.02,
        mainAxisSpacing: screenSize.height * 0.02,
        childAspectRatio: childAspectRatio,
        children: [
          _buildGridItem(
            context,
            'assets/images/01.png',
            '肚子餓',
            screenSize,
            isLandscape,
            onTap: () async {
              _audioPlayer.play(AssetSource('audios/5.mp3'));
            },
          ),
          _buildGridItem(
            context,
            'assets/images/02.png',
            '口渴',
            screenSize,
            isLandscape,
            onTap: () async {
              _audioPlayer.play(AssetSource('audios/2.mp3'));
            },
          ),
          _buildGridItem(
            context,
            'assets/images/03.png',
            '小號',
            screenSize,
            isLandscape,
            onTap: () async {
              _audioPlayer.play(AssetSource('audios/4.mp3'));
            },
          ),
          _buildGridItem(
            context,
            'assets/images/04.png',
            '大號',
            screenSize,
            isLandscape,
            onTap: () async {
              _audioPlayer.play(AssetSource('audios/3.mp3'));
            },
          ),
          _buildGridItem(
            context,
            'assets/images/05.png',
            '換尿布',
            screenSize,
            isLandscape,
            onTap: () async {
              _audioPlayer.play(AssetSource('audios/8.mp3'));
            },
          ),
          _buildGridItem(
            context,
            'assets/images/06.png',
            '翻身',
            screenSize,
            isLandscape,
            onTap: () async {
              _audioPlayer.play(AssetSource('audios/12.mp3'));
            },
          ),
          _buildGridItem(
            context,
            'assets/images/07.png',
            '很熱',
            screenSize,
            isLandscape,
            onTap: () async {
              _audioPlayer.play(AssetSource('audios/7.mp3'));
            },
          ),
          _buildGridItem(
            context,
            'assets/images/08.png',
            '很冷',
            screenSize,
            isLandscape,
            onTap: () async {
              _audioPlayer.play(AssetSource('audios/6.mp3'));
            },
          ),
          _buildGridItem(
            context,
            'assets/images/10.png',
            '頭痛',
            screenSize,
            isLandscape,
            onTap: () async {
              _audioPlayer.play(AssetSource('audios/10.mp3'));
            },
          ),
          _buildGridItem(
            context,
            'assets/images/11.png',
            '腹痛',
            screenSize,
            isLandscape,
            onTap: () async {
              _audioPlayer.play(AssetSource('audios/9.mp3'));
            },
          ),
          _buildGridItem(
            context,
            'assets/images/12.png',
            '下床',
            screenSize,
            isLandscape,
            onTap: () async {
              _audioPlayer.play(AssetSource('audios/1.mp3'));
            },
          ),
          _buildGridItem(
            context,
            'assets/images/09.png',
            '頭暈',
            screenSize,
            isLandscape,
            onTap: () async {
              _audioPlayer.play(AssetSource('audios/11.mp3'));
            },
          ),
        ],
      ),
    );
  }

  // 網格項目
  Widget _buildGridItem(BuildContext context, String imagePath, String label,
      Size screenSize, bool isLandscape,
      {required VoidCallback onTap}) {
    final imageSize =
        isLandscape ? screenSize.height * 0.30 : screenSize.width * 0.35;

    final fontSize =
        isLandscape ? screenSize.height * 0.05 : screenSize.width * 0.05;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: onTap,
          child: Container(
            width: imageSize,
            height: imageSize,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: screenSize.height * 0.01),
        FFButtonWidget(
          onPressed: onTap,
          text: label,
          options: FFButtonOptions(
            width:
                isLandscape ? screenSize.width * 0.1 : screenSize.width * 0.25,
            height: isLandscape ? 40.0 : 40.0,
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
            iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
            color: FlutterFlowTheme.of(context).primaryBtnText,
            textStyle: FlutterFlowTheme.of(context).displaySmall.override(
                  fontFamily: 'Poppins',
                  fontSize: fontSize,
                ),
            elevation: 2.0,
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).primaryBtnText,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ],
    );
  }

  // 統一的頁面標題區域
  Widget _buildPageHeader(
      BuildContext context, String title, String imagePath) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final containerHeight =
        isLandscape ? screenSize.height * 0.15 : screenSize.height * 0.1;

    final iconSize =
        isLandscape ? screenSize.height * 0.1 : screenSize.width * 0.15;

    final titleFontSize =
        isLandscape ? screenSize.height * 0.07 : screenSize.width * 0.08;

    return Container(
      width: double.infinity,
      height: containerHeight,
      color: Color(0xFFFFC1A1), // 保持與頁面主色調一致
      padding: EdgeInsets.symmetric(
          vertical: screenSize.height * 0.01,
          horizontal: screenSize.width * 0.02),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
                screenSize.width * 0.03, 0.0, 0.0, 0.0),
            child: Image.asset(
              imagePath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
                screenSize.width * 0.04, 0.0, 0.0, 0.0),
            child: Text(
              title,
              textAlign: TextAlign.start,
              style: FlutterFlowTheme.of(context).displaySmall.override(
                    fontFamily: 'Poppins',
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
