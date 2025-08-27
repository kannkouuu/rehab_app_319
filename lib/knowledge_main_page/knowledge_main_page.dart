import '../main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'knowledge_main_page_model.dart';
export 'knowledge_main_page_model.dart';

class KnowledgeMainPageWidget extends StatefulWidget {
  const KnowledgeMainPageWidget({Key? key}) : super(key: key);

  @override
  _KnowledgeMainPageWidgetState createState() =>
      _KnowledgeMainPageWidgetState();
}

class _KnowledgeMainPageWidgetState extends State<KnowledgeMainPageWidget> {
  late KnowledgeMainPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => KnowledgeMainPageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    _unfocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // 主 Column 結構
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 頂部標題
              _buildHeader(context, screenSize, isLandscape),

              // 中間內容區域 (可滾動)
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(isLandscape
                        ? screenSize.width * 0.03
                        : screenSize.width * 0.05),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // 保持原有佈局
                      children: [
                        // 衛教知識按鈕
                        _buildKnowledgeCard(
                          context,
                          'assets/images/education.png',
                          '衛教知識',
                          '學習口腔保健相關知識',
                          Color(0xFFE3F2FD),
                          screenSize,
                          isLandscape,
                          onTap: () => context.pushNamed('knowledge_page'),
                        ),

                        SizedBox(height: screenSize.height * 0.03),

                        // 健康問卷按鈕
                        _buildKnowledgeCard(
                          context,
                          'assets/images/questionnaire.png',
                          '口腔健康自我評估',
                          '進行口腔健康自我評估',
                          Color(0xFFFFF3E0),
                          screenSize,
                          isLandscape,
                          onTap: () => context.pushNamed('questions_page'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 底部導航欄
              BottomNavigation(
                  currentPage: 'knowledge_main_page', isSubPage: true),
            ],
          ),
        ),
      ),
    );
  }

  // 頂部標題
  Widget _buildHeader(BuildContext context, Size screenSize, bool isLandscape) {
    final headerHeight = isLandscape
        ? screenSize.height * 0.15 // 降低橫向高度
        : screenSize.height * 0.1; // 保持直向高度

    final titleFontSize = isLandscape
        ? screenSize.height * 0.07 // 降低橫向字體
        : screenSize.width * 0.08; // 調整直向字體

    return Container(
      width: double.infinity,
      height: headerHeight,
      color: FlutterFlowTheme.of(context).primaryBtnText,
      padding: EdgeInsets.all(screenSize.width * 0.02),
      child: Center(
        child: Text(
          '衛教總覽',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Poppins',
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  Widget _buildKnowledgeCard(
      BuildContext context,
      String imagePath,
      String title,
      String subtitle,
      Color backgroundColor,
      Size screenSize,
      bool isLandscape,
      {VoidCallback? onTap}) {
    final cardHeight = isLandscape
        ? screenSize.height * 0.2
        : screenSize.height * 0.14; // 增加卡片高度
    final iconSize = isLandscape
        ? screenSize.height * 0.06
        : screenSize.width * 0.12; // 調整圖標大小
    final titleFontSize = isLandscape
        ? screenSize.height * 0.05
        : screenSize.width * 0.06; // 調整標題字型大小
    final subtitleFontSize = isLandscape
        ? screenSize.height * 0.035
        : screenSize.width * 0.04; // 調整副標題字型大小

    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(screenSize.width * 0.04), // 統一 padding
            child: Row(
              children: [
                // 圖標
                Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      // 給Icon一點內邊距
                      padding: EdgeInsets.all(iconSize * 0.15),
                      child: Icon(
                        title == '衛教知識'
                            ? Icons.menu_book_rounded
                            : Icons.assignment_turned_in_rounded, // 更新圖標
                        size: iconSize * 0.7, // 圖標大小相對父容器
                        color: title == '衛教知識'
                            ? Color(0xFF1976D2)
                            : Color(0xFFFFA000), // 更新圖標顏色
                      ),
                    )),

                SizedBox(width: screenSize.width * 0.04),

                // 文字內容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: FlutterFlowTheme.of(context).titleLarge.override(
                              fontFamily: 'Poppins',
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      SizedBox(height: screenSize.height * 0.005),
                      Text(
                        subtitle,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Poppins',
                              fontSize: subtitleFontSize,
                              color: Colors.black54,
                            ),
                      ),
                    ],
                  ),
                ),

                // 箭頭圖標
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black38,
                  size: isLandscape
                      ? screenSize.height * 0.05
                      : screenSize.width * 0.06,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
