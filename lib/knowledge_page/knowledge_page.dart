import '../main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'knowledge_page_model.dart';
export 'knowledge_page_model.dart';

class KnowledgePageWidget extends StatefulWidget {
  const KnowledgePageWidget({Key? key}) : super(key: key);

  @override
  _KnowledgePageWidgetState createState() => _KnowledgePageWidgetState();
}

class _KnowledgePageWidgetState extends State<KnowledgePageWidget> {
  late KnowledgePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();

  // 衛教知識內容
  final List<Map<String, dynamic>> knowledgeBlocks = [
    {
      'title': '正確刷牙方式',
      'content': '正確刷牙方式\n\n'
          '• 使用貝氏刷牙法。\n'
          '  ∘ 刷毛靠在牙齒和牙齦相交界處，將刷毛傾斜45度。\n'
          '  ∘ 上顎：刷毛朝上呈45度角。\n'
          '  ∘ 下顎：刷毛朝下呈45度角。\n'
          '  ∘ 牙刷就定位後，開始作短距離的水平(左右)移動，一次刷兩顆牙，刷約10次，最後幾次往咬合面旋轉。\n\n'
          '• 每天至少刷牙兩次，早晚各一次。\n'
          '• 每次刷牙時間約2～3分鐘。\n'
          '• 更換牙刷每3個月一次或刷毛彎曲即更換。',
      'icon': Icons.cleaning_services,
      'color': Color(0xFFE3F2FD),
    },
    {
      'title': '日常清潔與保健建議',
      'content': '日常清潔與保健建議\n\n'
          '• 使用軟毛牙刷，減少牙齦損傷。\n'
          '• 選用含氟或抗敏牙膏，降低蛀牙與敏感不適。\n'
          '• 若手部靈活度降低，可選擇電動牙刷或加大握把的牙刷。\n'
          '• 每日使用牙線或牙間刷，協助清除牙縫間牙菌斑。\n\n'
          '• 口乾症處理：\n'
          '  ∘ 小口多次飲水（避免含糖飲料）。\n'
          '  ∘ 使用人工唾液或保濕口腔噴劑。\n'
          '  ∘ 咀嚼無糖口香糖或含木糖醇的含片，促進唾液分泌。',
      'icon': Icons.brush,
      'color': Color(0xFFF3E5F5),
    },
    {
      'title': '假牙使用與保養',
      'content': '假牙使用與保養\n\n'
          '• 每日取下清潔：\n'
          '  ∘ 使用假牙專用清潔劑與軟刷輕刷，避免用牙膏（易磨損）。\n\n'
          '• 晚上睡前取下假牙，讓口腔黏膜休息，浸泡於清水或假牙保養液中。\n\n'
          '• 若假牙鬆動或摩擦造成潰瘍，立即就醫調整。\n\n'
          '• 定期檢查假牙適配性（建議1年1次）。',
      'icon': Icons.favorite,
      'color': Color(0xFFE8F5E8),
    },
    {
      'title': '定期檢查與口腔癌預防',
      'content': '定期檢查與口腔癌預防\n\n'
          '• 每半年定期口腔檢查與洗牙，早期發現問題。\n\n'
          '• 檢查口腔內是否有不癒合潰瘍、紅白斑、腫塊或疼痛。\n\n'
          '• 戒菸限酒，減少致癌風險。\n\n'
          '• 補充均衡營養（維生素A、C、E對口腔黏膜健康有益）。',
      'icon': Icons.shield,
      'color': Color(0xFFFFF3E0),
    },
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => KnowledgePageModel());
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
                        ? screenSize.width * 0.02
                        : screenSize.width * 0.04),
                    child: Column(
                      children: knowledgeBlocks.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> block = entry.value;

                        return Column(
                          children: [
                            _buildKnowledgeBlock(
                              context,
                              block['title'],
                              block['content'],
                              block['icon'],
                              block['color'],
                              screenSize,
                              isLandscape,
                            ),
                            if (index < knowledgeBlocks.length - 1)
                              SizedBox(height: screenSize.height * 0.02),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // 底部導航欄
              BottomNavigation(currentPage: 'knowledge_page', isSubPage: true),
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
        isLandscape ? screenSize.height * 0.07 : screenSize.width * 0.08;

    return Container(
      width: double.infinity,
      height: headerHeight,
      color: FlutterFlowTheme.of(context).primaryBtnText,
      padding: EdgeInsets.all(screenSize.width * 0.02),
      child: Center(
        child: Text(
          '衛教知識',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Poppins',
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  Widget _buildKnowledgeBlock(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
    Size screenSize,
    bool isLandscape,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          width:
              isLandscape ? screenSize.height * 0.08 : screenSize.width * 0.12,
          height:
              isLandscape ? screenSize.height * 0.08 : screenSize.width * 0.12,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: isLandscape
                ? screenSize.height * 0.05
                : screenSize.width * 0.08,
            color: Color(0xFF1976D2),
          ),
        ),
        title: Text(
          title,
          style: FlutterFlowTheme.of(context).titleMedium.override(
                fontFamily: 'Poppins',
                fontSize: isLandscape
                    ? screenSize.height * 0.05
                    : screenSize.width * 0.05,
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(
          '了解口腔健康的重要性',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Poppins',
                fontSize: isLandscape
                    ? screenSize.height * 0.035
                    : screenSize.width * 0.04,
                color: Colors.black54,
              ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: Text(
              content,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Poppins',
                    fontSize: isLandscape
                        ? screenSize.height * 0.035
                        : screenSize.width * 0.04,
                    color: Colors.black87,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
