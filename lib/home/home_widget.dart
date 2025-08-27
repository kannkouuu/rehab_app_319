import 'dart:convert';
import '../main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/bottom_navigation.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'home_model.dart';
export 'home_model.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({Key? key}) : super(key: key);

  @override
  _HomeWidgetState createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  late HomeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();

  var money1;

  Future money() async {
    try {
      var url = Uri.parse(ip + "money.php");
      final responce = await http.post(url, body: {
        "account": FFAppState().accountnumber,
      }).timeout(Duration(seconds: 10));
      
      if (responce.statusCode == 200) {
        var data = json.decode(responce.body);
        if (mounted) {
          setState(() {
            money1 = data['coin']['coin'];
          });
        }
        //print(data['coin']['coin']);
      } else {
        print('Money API 錯誤: HTTP ${responce.statusCode}');
      }
    } catch (e) {
      print('Money API 請求失敗: $e');
      // 設置默認值或保持當前值
      if (mounted && money1 == null) {
        setState(() {
          money1 = 0; // 設置默認值
        });
      }
    }
  }

  void cycle() async {
    try {
      var url = Uri.parse(ip + "delete.php");
      await http.post(url, body: {
        "account": FFAppState().accountnumber,
      }).timeout(Duration(seconds: 10));
    } catch (e) {
      print('Cycle API 錯誤: $e');
    }
  }

  // 顯示退出確認對話框
  Future<bool> _showExitConfirmDialog() async {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final fontSize =
        isLandscape ? screenSize.height * 0.035 : screenSize.width * 0.045;

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 不允許點擊外部關閉
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            '確認退出',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize * 1.1,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            '您確定要退出應用程式嗎？',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 取消按鈕
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '取消',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // 確定按鈕
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.red[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '退出',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeModel());

    // 初始化時檢查金幣和未讀訊息
    money();

    // 檢查未讀訊息（如果用戶已登入）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && FFAppState().accountnumber.isNotEmpty) {
        FFAppState().checkUnreadNotifications();
      }
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return WillPopScope(
      onWillPop: () async {
        // 攔截返回鍵事件，顯示退出確認對話框
        final bool shouldExit = await _showExitConfirmDialog();
        if (shouldExit) {
          // 用戶選擇退出，關閉應用程式
          SystemNavigator.pop();
        }
        return false; // 防止預設的返回行為
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(_unfocusNode),
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBtnText,
          body: SafeArea(
            top: true,
            bottom: false, // 關閉底部安全區域，讓導航欄可以貼合底部
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // 歡迎區域 - 改為水平佈局
                _buildWelcomeHeader(context, screenSize, isLandscape),

                // 中間選單區域 (可滾動)
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildMenuOptions(context, screenSize, isLandscape),
                  ),
                ),

                // 底部導航欄
                BottomNavigation(currentPage: 'home'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 重新設計的歡迎區域 - 水平佈局
  Widget _buildWelcomeHeader(
      BuildContext context, Size screenSize, bool isLandscape) {
    // 計算響應式尺寸
    final headerPadding = EdgeInsets.symmetric(
      horizontal: screenSize.width * 0.05,
      vertical:
          isLandscape ? screenSize.height * 0.02 : screenSize.height * 0.02,
    );

    final greetingFontSize =
        isLandscape ? screenSize.height * 0.05 : screenSize.width * 0.05;

    final coinIconSize =
        isLandscape ? screenSize.height * 0.08 : screenSize.width * 0.12;

    final coinFontSize =
        isLandscape ? screenSize.height * 0.05 : screenSize.width * 0.07;

    return Container(
      width: double.infinity,
      padding: headerPadding,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBtnText,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左側 - 歡迎詞
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hello ',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Poppins',
                            fontSize: greetingFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      FFAppState().nickname,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Poppins',
                            fontSize: greetingFontSize,
                          ),
                    ),
                  ],
                ),
                Text(
                  '繼續努力加油!!!',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        fontSize: greetingFontSize * 0.8,
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),

          // 右側 - 金幣數量
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/25.jpg',
                width: coinIconSize,
                height: coinIconSize,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 8),
              Text(
                '$money1' + '個',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Poppins',
                      fontSize: coinFontSize,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF9800),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 重新設計的選單區域
  Widget _buildMenuOptions(
      BuildContext context, Size screenSize, bool isLandscape) {
    // 響應式尺寸和間距計算
    final padding = EdgeInsets.all(
        isLandscape ? screenSize.width * 0.02 : screenSize.width * 0.03);

    return Padding(
      padding: padding,
      child: isLandscape
          ? _buildLandscapeMenuGrid(context, screenSize)
          : _buildPortraitMenuList(context, screenSize),
    );
  }

  // 橫向菜單 - 網格佈局
  Widget _buildLandscapeMenuGrid(BuildContext context, Size screenSize) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2, // 調整比例以容納更多項目
      mainAxisSpacing: screenSize.height * 0.02,
      crossAxisSpacing: screenSize.width * 0.02,
      children: [
        _buildMenuOption(
          context,
          'assets/images/23.png',
          '需求表達',
          Color(0xFFFFD3C4),
          screenSize,
          true,
          onTap: () => context.pushNamed('need'),
        ),
        _buildMenuOption(
          context,
          'assets/images/22.png',
          '復健訓練',
          Color(0xFF688EEA),
          screenSize,
          true,
          onTap: () => context.pushNamed('train'),
        ),
        _buildMenuOption(
          context,
          'assets/images/knowledge.png', // 新增衛教知識圖標
          '衛教知識',
          Color(0xFFE8F5E8),
          screenSize,
          true,
          onTap: () => context.pushNamed('knowledge_main_page'),
        ),
        _buildMenuOption(
          context,
          'assets/images/24.png',
          '諮詢社群',
          Color(0xFFD4FFC4),
          screenSize,
          true,
          onTap: () => context.pushNamed('LINE'),
        ),
        _buildMenuOption(
          context,
          'assets/images/21.png',
          '設定',
          FlutterFlowTheme.of(context).grayIcon,
          screenSize,
          true,
          onTap: () => context.pushNamed('settings_menu'),
        ),
      ],
    );
  }

  // 直向菜單 - 列表佈局
  Widget _buildPortraitMenuList(BuildContext context, Size screenSize) {
    final itemHeight = screenSize.height * 0.1;
    final spacing = screenSize.height * 0.01;

    return Column(
      children: [
        _buildMenuOption(
          context,
          'assets/images/23.png',
          '需求表達',
          Color(0xFFFFD3C4),
          screenSize,
          false,
          height: itemHeight,
          onTap: () => context.pushNamed('need'),
        ),
        SizedBox(height: spacing),
        _buildMenuOption(
          context,
          'assets/images/22.png',
          '復健訓練',
          Color(0xFF688EEA),
          screenSize,
          false,
          height: itemHeight,
          onTap: () => context.pushNamed('train'),
        ),
        SizedBox(height: spacing),
        _buildMenuOption(
          context,
          'assets/images/knowledge.png', // 新增衛教知識圖標
          '衛教知識',
          Color(0xFFE8F5E8),
          screenSize,
          false,
          height: itemHeight,
          onTap: () => context.pushNamed('knowledge_main_page'),
        ),
        SizedBox(height: spacing),
        _buildMenuOption(
          context,
          'assets/images/24.png',
          '諮詢社群',
          Color(0xFFD4FFC4),
          screenSize,
          false,
          height: itemHeight,
          onTap: () => context.pushNamed('LINE'),
        ),
        SizedBox(height: spacing),
        _buildMenuOption(
          context,
          'assets/images/21.png',
          '設定',
          FlutterFlowTheme.of(context).grayIcon,
          screenSize,
          false,
          height: itemHeight,
          onTap: () => context.pushNamed('settings_menu'),
        ),
      ],
    );
  }

  // 優化的選單選項
  Widget _buildMenuOption(BuildContext context, String imagePath, String label,
      Color backgroundColor, Size screenSize, bool isLandscape,
      {double? height, VoidCallback? onTap}) {
    // 響應式尺寸計算
    final iconSize =
        isLandscape ? screenSize.height * 0.1 : screenSize.height * 0.08;

    final fontSize =
        isLandscape ? screenSize.height * 0.1 : screenSize.width * 0.08;

    final borderRadius = BorderRadius.circular(12);

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Image.asset(
                  imagePath,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Poppins',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
