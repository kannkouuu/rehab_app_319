import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'preference_settings_model.dart';
export 'preference_settings_model.dart';

class PreferenceSettingsWidget extends StatefulWidget {
  const PreferenceSettingsWidget({Key? key}) : super(key: key);

  @override
  _PreferenceSettingsWidgetState createState() =>
      _PreferenceSettingsWidgetState();
}

class _PreferenceSettingsWidgetState extends State<PreferenceSettingsWidget> {
  late PreferenceSettingsModel _model;
  String _selectedLanguage = 'chinese'; // 預設為中文

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PreferenceSettingsModel());
    _loadPreference();
  }

  @override
  void dispose() {
    _model.dispose();
    _unfocusNode.dispose();
    super.dispose();
  }

  // 從 SharedPreferences 載入語言偏好設定
  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language_preference') ?? 'chinese';
    });
  }

  // 儲存語言偏好設定到 SharedPreferences
  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_preference', _selectedLanguage);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '偏好設定已儲存',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
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
        backgroundColor: FlutterFlowTheme.of(context).primaryBtnText,
        body: SafeArea(
          top: true,
          bottom: false, // 關閉底部安全區域，讓導航欄可以貼合底部
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 頂部標題
              _buildHeader(context, screenSize, isLandscape),

              // 中間內容區域
              Expanded(
                child: SingleChildScrollView(
                  child:
                      _buildLanguageSettings(context, screenSize, isLandscape),
                ),
              ),

              // 保存按鈕
              _buildSaveButton(context, screenSize, isLandscape),

              // 底部導航欄
              BottomNavigation(
                  currentPage: 'preference_settings', isSubPage: true),
            ],
          ),
        ),
      ),
    );
  }

  // 頂部標題
  Widget _buildHeader(BuildContext context, Size screenSize, bool isLandscape) {
    final headerHeight =
        isLandscape ? screenSize.height * 0.15 : screenSize.height * 0.1;

    final titleFontSize =
        isLandscape ? screenSize.height * 0.06 : screenSize.width * 0.07;

    return Container(
      width: double.infinity,
      height: headerHeight,
      color: FlutterFlowTheme.of(context).primaryBtnText,
      padding: EdgeInsets.all(screenSize.width * 0.02),
      child: Center(
        child: Text(
          '偏好設定',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Poppins',
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  // 語言設置區域
  Widget _buildLanguageSettings(
      BuildContext context, Size screenSize, bool isLandscape) {
    final sectionTitleSize =
        isLandscape ? screenSize.height * 0.05 : screenSize.width * 0.06;

    final optionTextSize =
        isLandscape ? screenSize.height * 0.04 : screenSize.width * 0.05;

    return Padding(
      padding: EdgeInsets.all(screenSize.width * 0.04),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              color: Color(0x33000000),
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(screenSize.width * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '語言選擇',
                style: FlutterFlowTheme.of(context).titleLarge.override(
                      fontFamily: 'Poppins',
                      fontSize: sectionTitleSize,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: screenSize.height * 0.02),

              // 中文選項
              RadioListTile<String>(
                title: Text(
                  '中文',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        fontSize: optionTextSize,
                      ),
                ),
                value: 'chinese',
                groupValue: _selectedLanguage,
                activeColor: Color(0xFF688EEA),
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
              ),

              // 台語選項
              RadioListTile<String>(
                title: Text(
                  '台語',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        fontSize: optionTextSize,
                      ),
                ),
                value: 'taiwanese',
                groupValue: _selectedLanguage,
                activeColor: Color(0xFF688EEA),
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 保存按鈕
  Widget _buildSaveButton(
      BuildContext context, Size screenSize, bool isLandscape) {
    final buttonWidth =
        isLandscape ? screenSize.width * 0.2 : screenSize.width * 0.5;

    final buttonHeight =
        isLandscape ? screenSize.height * 0.08 : screenSize.height * 0.06;

    final buttonTextSize =
        isLandscape ? screenSize.height * 0.04 : screenSize.width * 0.05;

    return Padding(
      padding: EdgeInsets.only(bottom: screenSize.height * 0.02),
      child: FFButtonWidget(
        onPressed: _savePreference,
        text: '儲存設定',
        options: FFButtonOptions(
          width: buttonWidth,
          height: buttonHeight,
          padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
          iconPadding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
          color: Color(0xFFFFAC8F),
          textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: buttonTextSize,
                fontWeight: FontWeight.bold,
              ),
          elevation: 3,
          borderSide: BorderSide(
            color: Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
