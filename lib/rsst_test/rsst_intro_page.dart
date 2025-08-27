import 'dart:io';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'rsst_test_page.dart';
import 'rsst_result_page.dart';

class RsstIntroPage extends StatefulWidget {
  const RsstIntroPage({Key? key}) : super(key: key);

  @override
  _RsstIntroPageState createState() => _RsstIntroPageState();
}

class _RsstIntroPageState extends State<RsstIntroPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();

  bool _isUploading = false;
  bool _permissionsGranted = false; // 追蹤權限狀態

  @override
  void initState() {
    super.initState();
    // 在頁面初始化時請求權限
    _requestPermissions();
  }

  // 請求所有必要的權限
  Future<void> _requestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
      ].request();

      // 確認所有權限都已獲得授權
      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (status != PermissionStatus.granted) {
          allGranted = false;
        }
      });

      setState(() {
        _permissionsGranted = allGranted;
      });

      if (!allGranted) {
        // 如果有權限未獲得授權，顯示提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('需要麥克風權限才能進行測驗和錄音'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: '設定',
                onPressed: () {
                  openAppSettings(); // 打開應用程式設定頁面
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('請求權限時出錯: $e');
    }
  }

  @override
  void dispose() {
    _unfocusNode.dispose();
    super.dispose();
  }

  // 上傳音檔的功能
  Future<void> _uploadAudioFile() async {
    // 再次檢查權限
    if (!await _checkPermissions()) {
      return;
    }

    setState(() => _isUploading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wav'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        print('上傳檔案路徑: ${file.path}');

        // 顯示上傳中提示對話框
        if (mounted) {
          // 先顯示一個進度提示對話框
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 15),
                    Text('音檔上傳中，即將進行處理與吞嚥分析...'),
                  ],
                ),
              );
            },
          );

          // 延遲一下確保對話框顯示，然後導航到結果頁面
          Future.delayed(Duration(milliseconds: 800), () {
            // 關閉對話框
            Navigator.of(context).pop();

            // 導航到結果頁面，音檔處理會在結果頁面自動進行
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RsstResultPage(
                  swallowCount: 0, // 初始設為0，會在結果頁面透過模型推論更新
                  recordingPath: file.path,
                  isFromUpload: true, // 標記為上傳模式，這樣會顯示推論結果
                ),
              ),
            );
          });
        }
      } else {
        // 用戶取消了選擇
        setState(() => _isUploading = false);
      }
    } catch (e) {
      print('上傳音檔時出錯: $e');
      if (mounted) {
        // 如果對話框正在顯示，先關閉
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('處理音檔時出錯: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isUploading = false);
      }
    }
  }

  // 檢查是否有必要的權限
  Future<bool> _checkPermissions() async {
    // 確認麥克風權限
    final micStatus = await Permission.microphone.status;

    if (micStatus.isGranted) {
      return true;
    }

    // 如果沒有權限，再次請求
    bool permissionGranted = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('需要權限'),
          content: Text('此應用程式需要麥克風權限才能進行測驗和錄音。'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final status = await Permission.microphone.request();
                if (status.isGranted) {
                  permissionGranted = true;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('未獲得麥克風權限，無法進行測驗'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('授予權限'),
            ),
          ],
        );
      },
    );

    // 如果對話框後權限仍未獲得
    if (!permissionGranted) {
      bool manuallyGranted = await _requestManualPermissionIfNeeded();
      return manuallyGranted;
    }

    return permissionGranted;
  }

  // 如果常規請求權限失敗，提示用戶手動開啟設定
  Future<bool> _requestManualPermissionIfNeeded() async {
    bool userWentToSettings = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('權限被拒絕'),
          content: Text('沒有麥克風權限，應用程式無法進行錄音。請在設定中手動授予權限。'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                userWentToSettings = true;
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: Text('開啟設定'),
            ),
          ],
        );
      },
    );

    // 如果用戶去了設定頁面，再次檢查權限
    if (userWentToSettings) {
      final micStatus = await Permission.microphone.status;
      return micStatus.isGranted;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_unfocusNode),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBtnText,
        appBar: AppBar(
          backgroundColor: Color(0xFF90BDF9),
          title: Text(
            '復健成效測驗-RSST',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 22,
                ),
          ),
          centerTitle: true,
          elevation: 2,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 1,
            decoration: BoxDecoration(
              color: Color(0xFF90BDF9),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(20, 20, 20, 0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4,
                            color: Color(0x33000000),
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              '什麼是 RSST 測驗？',
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: 'Poppins',
                                    color: Color(0xFFC50D1C),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 15),
                            AutoSizeText(
                              'RSST (Repetitive Saliva Swallowing Test) 是一種評估吞嚥能力的簡易測驗，通過計算在特定時間內的吞嚥次數，來評估吞嚥功能。',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                  ),
                            ),
                            SizedBox(height: 20),
                            AutoSizeText(
                              '測驗流程：',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF2E5AAC),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(10, 0, 10, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStepItem('1', '按下「開始測驗」按鈕。'),
                                  _buildStepItem(
                                      '2', '您有5秒鐘準備時間，請將手機放置於指定位置以便錄製吞嚥聲音。'),
                                  _buildStepItem('3', '聽到提示音後，開始盡可能多次地吞口水。'),
                                  _buildStepItem(
                                      '4', '測驗會持續30秒，完成後系統會自動計算您的吞嚥次數。'),
                                  _buildStepItem('5', '結果頁面會顯示您的吞嚥次數和音頻波形分析圖。'),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            AutoSizeText(
                              '準備事項：',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF2E5AAC),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(10, 0, 10, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildNoteItem('測試前喝一小口水，保持口腔稍微濕潤。'),
                                  _buildNoteItem(
                                      '測試時身體保持直立坐姿，頭部自然位置，不要過度前傾或後仰。'),
                                  _buildNoteItem(
                                      '手機應放在頸部喉結上方，不要貼得太緊，以免影響錄音效果。'),
                                  _buildNoteItem('測試環境應盡量安靜，避免干擾吞嚥聲音的錄製。'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fade(duration: 400.ms).slide(duration: 500.ms),

                  // 權限提示（如果尚未授予）
                  if (!_permissionsGranted)
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(20, 10, 20, 0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Color(0xFFFFD700)),
                        ),
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFC50D1C)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '需要麥克風權限才能進行測驗和錄音',
                                style: TextStyle(color: Color(0xFFC50D1C)),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _requestPermissions();
                              },
                              child: Text('授予權限'),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 測驗按鈕
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 30, 0, 10),
                    child: ElevatedButton(
                      onPressed: () async {
                        // 檢查權限後再導航
                        if (await _checkPermissions()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RsstTestPage(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF4DB60),
                        foregroundColor: Color(0xFFC50D1C),
                        padding: EdgeInsetsDirectional.fromSTEB(40, 20, 40, 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 3,
                      ),
                      child: AutoSizeText(
                        '開始測驗',
                        style: FlutterFlowTheme.of(context).titleLarge.override(
                              fontFamily: 'Poppins',
                              color: Color(0xFFC50D1C),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ).animate().fade(duration: 500.ms).scale(duration: 500.ms),

                  /*
                  //上傳音檔按鈕 測試模型用 部屬時刪除
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 30),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.upload_file, color: Colors.white),
                      label: Text(
                        '上傳音檔分析',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2E5AAC),
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isUploading ? null : _uploadAudioFile,
                    ),
                  ).animate().fade(duration: 500.ms, delay: 200.ms),

                  // 上傳進度指示器
                  if (_isUploading)
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 30),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFF4DB60)),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '選擇音檔中...',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    */
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(0xFFF4DB60),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Poppins',
                      color: Color(0xFFC50D1C),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String text) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFF2E5AAC),
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
