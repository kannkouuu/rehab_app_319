import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/app_state.dart';
import 'dart:async';

/// 通用底部導航欄元件
/// [currentPage] 當前頁面名稱，用於禁用當前頁面的點擊
/// [isSubPage] 是否為子頁面，子頁面會顯示返回按鈕
class BottomNavigation extends StatefulWidget {
  final String currentPage;
  final bool isSubPage;

  const BottomNavigation({
    Key? key,
    required this.currentPage,
    this.isSubPage = false,
  }) : super(key: key);

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation>
    with WidgetsBindingObserver {
  Timer? _notificationCheckTimer;
  int _consecutiveFailures = 0; // 連續失敗次數
  static const int maxConsecutiveFailures = 3; // 最大連續失敗次數
  static const Duration normalCheckInterval = Duration(seconds: 30); // 正常檢查間隔
  static const Duration backoffInterval = Duration(minutes: 5); // 失敗後退避間隔

  @override
  void initState() {
    super.initState();
    // 添加生命週期觀察者
    WidgetsBinding.instance.addObserver(this);

    // 組件初始化時立即檢查未讀通知
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotifications();
    });

    // 設置定期檢查未讀通知
    _startNotificationTimer();
  }

  @override
  void dispose() {
    // 移除生命週期觀察者
    WidgetsBinding.instance.removeObserver(this);
    // 清理計時器
    _notificationCheckTimer?.cancel();
    super.dispose();
  }

  /// 開始通知檢查計時器
  void _startNotificationTimer() {
    // 根據失敗次數決定檢查間隔
    Duration interval = _consecutiveFailures >= maxConsecutiveFailures
        ? backoffInterval
        : normalCheckInterval;

    _notificationCheckTimer = Timer.periodic(
      interval,
      (timer) => _checkNotifications(),
    );
  }

  /// 重新啟動計時器（當失敗次數改變時）
  void _restartTimer() {
    _notificationCheckTimer?.cancel();
    _startNotificationTimer();
  }

  /// 檢查未讀通知
  Future<void> _checkNotifications() async {
    try {
      final appState = context.read<FFAppState>();
      await appState.checkUnreadNotifications();

      // 檢查成功，重設失敗計數器
      if (_consecutiveFailures > 0) {
        _consecutiveFailures = 0;
        _restartTimer(); // 恢復正常檢查頻率
      }
    } catch (e) {
      // 增加失敗計數器
      _consecutiveFailures++;

      // 如果連續失敗次數達到閾值，降低檢查頻率
      if (_consecutiveFailures == maxConsecutiveFailures) {
        _restartTimer(); // 切換到較長的檢查間隔
      }

      // 只在調試模式下打印錯誤
      assert(() {
        print('導航欄檢查通知失敗 (第 $_consecutiveFailures 次): $e');
        return true;
      }());
    }
  }

  /// 手動刷新通知狀態
  Future<void> _refreshNotifications() async {
    await _checkNotifications();
  }

  /// 應用程式進入前景時檢查通知
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 應用程式回到前景時檢查通知，但如果之前失敗過多次，給一些緩衝時間
      if (_consecutiveFailures < maxConsecutiveFailures) {
        _checkNotifications();
      } else {
        // 重設失敗計數器，給網路狀況一個重新開始的機會
        _consecutiveFailures = 0;
        _restartTimer();
        // 延遲檢查，避免立即重試
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _checkNotifications();
          }
        });
      }
    } else if (state == AppLifecycleState.paused) {
      // 應用程式進入背景時，可以選擇停止檢查以節省資源
      _notificationCheckTimer?.cancel();
    }
  }

  // 主頁的退出確認對話框
  Future<bool> _showExitConfirmDialog(BuildContext context) async {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final fontSize =
        isLandscape ? screenSize.height * 0.035 : screenSize.width * 0.045;

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    
    // 獲取底部安全區域高度，用於 iOS 設備的 Home Indicator
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      color: FlutterFlowTheme.of(context).primaryBtnText,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: isLandscape ? screenHeight * 0.15 : screenHeight * 0.15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildBottomNavItem(
                  context,
                  'assets/images/17.jpg',
                  (widget.isSubPage || widget.currentPage == 'home') ? '返回' : '主頁',
                  onTap: widget.isSubPage
                      ? () => Navigator.pop(context) // 子頁面直接返回
                      : widget.currentPage == 'home'
                          ? () async {
                              // 主頁顯示退出確認對話框
                              final bool shouldExit =
                                  await _showExitConfirmDialog(context);
                              if (shouldExit) {
                                SystemNavigator.pop();
                              }
                            }
                          : (widget.currentPage != 'home'
                              ? () => context.pushNamed('home')
                              : null),
                ),
                _buildBottomNavItem(
                  context,
                  'assets/images/18.jpg',
                  '使用紀錄',
                  onTap: widget.currentPage != 'documental'
                      ? () => context.pushNamed('documental')
                      : null,
                ),
                _buildNotificationNavItem(
                  context,
                  'assets/images/19.jpg',
                  '新通知',
                  onTap: widget.currentPage != 'notice'
                      ? () async {
                          // 點擊新通知時，先刷新通知狀態，然後標記為已檢查
                          await _refreshNotifications();
                          context.read<FFAppState>().markNotificationsAsChecked();
                          context.pushNamed('notice');
                        }
                      : null,
                  onLongPress: widget.currentPage != 'notice'
                      ? () async {
                          // 長按通知按鈕可以手動刷新通知狀態
                          await _refreshNotifications();
                          // 顯示刷新完成的提示
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('通知狀態已刷新'),
                                duration: Duration(seconds: 1),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      : null,
                ),
                _buildBottomNavItem(
                  context,
                  'assets/images/20.jpg',
                  '關於',
                  onTap: widget.currentPage != 'about'
                      ? () => context.pushNamed('about')
                      : null,
                ),
              ],
            ),
          ),
          // 為 iOS 添加底部安全區域填充
          Container(
            height: bottomPadding,
            color: FlutterFlowTheme.of(context).primaryBtnText,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context,
    String imagePath,
    String label, {
    VoidCallback? onTap,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final iconWidth = isLandscape ? screenHeight * 0.08 : screenWidth * 0.12;
    final iconHeight = isLandscape ? screenHeight * 0.08 : screenWidth * 0.12;
    final fontSize = isLandscape ? screenHeight * 0.03 : screenWidth * 0.04;

    // 判斷是否為當前頁面（不可點擊）
    final isCurrentPage = onTap == null;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: isCurrentPage ? 0.6 : 1.0, // 當前頁面設置半透明效果
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imagePath,
                width: iconWidth,
                height: iconHeight,
                fit: BoxFit.contain,
              ),
              SizedBox(height: screenHeight * 0.005),
              Text(
                label,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Poppins',
                      fontSize: fontSize,
                      color: isCurrentPage
                          ? Colors.grey[600] // 當前頁面使用灰色文字
                          : null,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 專門為新通知按鈕創建的方法，支持顯示未讀紅點
  Widget _buildNotificationNavItem(
    BuildContext context,
    String imagePath,
    String label, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final iconWidth = isLandscape ? screenHeight * 0.08 : screenWidth * 0.12;
    final iconHeight = isLandscape ? screenHeight * 0.08 : screenWidth * 0.12;
    final fontSize = isLandscape ? screenHeight * 0.03 : screenWidth * 0.04;

    // 判斷是否為當前頁面（不可點擊）
    final isCurrentPage = onTap == null;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Opacity(
          opacity: isCurrentPage ? 0.6 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 使用Stack來在圖標上顯示紅點
              Stack(
                children: [
                  Image.asset(
                    imagePath,
                    width: iconWidth,
                    height: iconHeight,
                    fit: BoxFit.contain,
                  ),
                  // 使用Consumer來監聽未讀通知狀態
                  Consumer<FFAppState>(
                    builder: (context, appState, child) {
                      // 只有當有未讀通知且不是當前頁面時才顯示紅點
                      if (appState.hasUnreadNotifications && !isCurrentPage) {
                        return Positioned(
                          top: 0,
                          right: iconWidth * 0.05,
                          child: Container(
                            width: iconWidth * 0.35,
                            height: iconWidth * 0.35,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.0,
                              ),
                            ),
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),
              Text(
                label,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Poppins',
                      fontSize: fontSize,
                      color: isCurrentPage ? Colors.grey[600] : null,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
