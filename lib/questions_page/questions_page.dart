import '../main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'questions_page_model.dart';
export 'questions_page_model.dart';

class QuestionsPageWidget extends StatefulWidget {
  const QuestionsPageWidget({Key? key}) : super(key: key);

  @override
  _QuestionsPageWidgetState createState() => _QuestionsPageWidgetState();
}

class _QuestionsPageWidgetState extends State<QuestionsPageWidget> {
  late QuestionsPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();

  // 存儲用戶的答案
  List<bool?> answers = List.filled(5, null);

  // 問題列表
  final List<Map<String, dynamic>> questions = [
    {
      'question': '您剩下多少顆自然牙？(假牙不算)',
      'trueText': '0到19顆',
      'falseText': '20顆(含)以上',
    },
    {
      'question': '和半年前相比，您吃硬的食物有任何困難？',
      'trueText': '是',
      'falseText': '否',
    },
    {
      'question': '最近您有被茶或湯嗆到過？',
      'trueText': '是',
      'falseText': '否',
    },
    {
      'question': '您經常感到嘴巴乾燥嗎？',
      'trueText': '是',
      'falseText': '否',
    },
    {
      'question': '口腔輪替運動(每秒發出/ta (踏)/音的次數)',
      'trueText': '小於6次/秒',
      'falseText': '6次/秒(含)以上',
    },
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => QuestionsPageModel());
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
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBtnText,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: FlutterFlowTheme.of(context).primaryText,
              size: 30,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            '口腔自我檢核表',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Poppins',
                  fontSize: isLandscape
                      ? screenSize.height * 0.08
                      : screenSize.width * 0.08,
                  fontWeight: FontWeight.bold,
                ),
          ),
          centerTitle: true,
          elevation: 2,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 說明文字
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '口腔衰弱評估問卷 (OF-5)\n請根據您的實際情況選擇最符合的答案',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        fontFamily: 'Poppins',
                        fontSize: isLandscape
                            ? screenSize.height * 0.04
                            : screenSize.width * 0.045,
                        color: Colors.black87,
                      ),
                ),
              ),

              // 問題列表
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: questions.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> question = entry.value;

                        return Column(
                          children: [
                            _buildQuestionCard(
                              context,
                              index,
                              question['question'],
                              question['trueText'],
                              question['falseText'],
                              screenSize,
                              isLandscape,
                            ),
                            SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // 提交按鈕
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed:
                      _allQuestionsAnswered() ? _submitQuestionnaire : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allQuestionsAnswered()
                        ? Color(0xFF4CAF50)
                        : Colors.grey[300],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '提交',
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                          fontFamily: 'Poppins',
                          fontSize: isLandscape
                              ? screenSize.height * 0.06
                              : screenSize.width * 0.06,
                          fontWeight: FontWeight.bold,
                          color: _allQuestionsAnswered()
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    int index,
    String question,
    String trueText,
    String falseText,
    Size screenSize,
    bool isLandscape,
  ) {
    final questionFontSize =
        isLandscape ? screenSize.height * 0.04 : screenSize.width * 0.045;
    final optionFontSize =
        isLandscape ? screenSize.height * 0.035 : screenSize.width * 0.04;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 問題編號和內容
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question,
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'Poppins',
                          fontSize: questionFontSize,
                          color: Colors.black87,
                        ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // 選項
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    context,
                    trueText,
                    true,
                    index,
                    answers[index] == true,
                    optionFontSize,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildOptionButton(
                    context,
                    falseText,
                    false,
                    index,
                    answers[index] == false,
                    optionFontSize,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String text,
    bool value,
    int questionIndex,
    bool isSelected,
    double fontSize,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSelected
            ? (value ? Color(0xFFFFCDD2) : Color(0xFFE8F5E8))
            : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? (value ? Color(0xFFE57373) : Color(0xFF81C784))
              : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              answers[questionIndex] = value;
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodyLarge.override(
                    fontFamily: 'Poppins',
                    fontSize: fontSize,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? (value ? Color(0xFFD32F2F) : Color(0xFF388E3C))
                        : Colors.black87,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  bool _allQuestionsAnswered() {
    return answers.every((answer) => answer != null);
  }

  void _submitQuestionnaire() {
    int trueCount = answers.where((answer) => answer == true).length;

    bool needsReferral = trueCount > 2;
    String resultStatus;
    String resultMessage;
    IconData resultIcon;
    Color resultIconColor;

    if (needsReferral) {
      resultStatus = '有口腔衰弱風險！';
      resultMessage = '您的評估結果為「有口腔衰弱風險」，建議您諮詢牙科或相關醫療專業人員進行進一步評估。';
      resultIcon = Icons.warning_amber_rounded;
      resultIconColor = Color(0xFFD32F2F);
    } else {
      resultStatus = '口腔功能良好！';
      resultMessage = '您的口腔功能狀況良好，請繼續保持良好的口腔衛生習慣與定期檢查。';
      resultIcon = Icons.check_circle_outline_rounded;
      resultIconColor = Color(0xFF388E3C);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: _buildResultDialogContent(
            context,
            resultStatus,
            resultMessage,
            resultIcon,
            resultIconColor,
          ),
        );
      },
    );
  }

  Widget _buildResultDialogContent(
    BuildContext context,
    String status,
    String message,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 60,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).headlineMedium.override(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                ),
                SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyLarge.copyWith(
                        height: 1.5,
                        color: Colors.black87,
                      ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 關閉對話框
                    context.pop(); // 返回到 knowledge_main_page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    elevation: 2,
                    shadowColor: iconColor.withOpacity(0.4),
                  ),
                  child: Text(
                    '完成',
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
