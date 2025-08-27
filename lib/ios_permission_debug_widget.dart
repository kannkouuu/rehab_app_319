import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class IOSPermissionDebugWidget extends StatefulWidget {
  @override
  _IOSPermissionDebugWidgetState createState() => _IOSPermissionDebugWidgetState();
}

class _IOSPermissionDebugWidgetState extends State<IOSPermissionDebugWidget> {
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    _addLog('=== iOS 權限調試工具啟動 ===');
    _addLog('平台: ${defaultTargetPlatform.toString()}');
    _checkAllPermissions();
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _debugLogs.add('[$timestamp] $message');
    });
    print(message);
  }

  Future<void> _checkAllPermissions() async {
    _addLog('開始檢查所有權限狀態...');
    
    List<Permission> permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ];

    Map<Permission, PermissionStatus> statuses = {};
    
    for (Permission permission in permissions) {
      try {
        PermissionStatus status = await permission.status;
        statuses[permission] = status;
        _addLog('權限 ${_getPermissionName(permission)}: $status');
      } catch (e) {
        _addLog('檢查權限 ${_getPermissionName(permission)} 時發生錯誤: $e');
        statuses[permission] = PermissionStatus.denied;
      }
    }

    setState(() {
      _permissionStatuses = statuses;
    });
    
    _addLog('權限狀態檢查完成');
  }

  Future<void> _requestPermission(Permission permission) async {
    _addLog('開始請求權限: ${_getPermissionName(permission)}');
    
    try {
      // 先檢查當前狀態
      PermissionStatus currentStatus = await permission.status;
      _addLog('請求前狀態: $currentStatus');
      
      // 請求權限
      PermissionStatus newStatus = await permission.request();
      _addLog('請求後狀態: $newStatus');
      
      setState(() {
        _permissionStatuses[permission] = newStatus;
      });

      // 根據結果給予相應的提示
      if (newStatus.isGranted) {
        _addLog('✅ 權限已授予: ${_getPermissionName(permission)}');
      } else if (newStatus.isPermanentlyDenied) {
        _addLog('❌ 權限被永久拒絕: ${_getPermissionName(permission)}');
        _showSettingsDialog(permission);
      } else if (newStatus.isDenied) {
        _addLog('⚠️ 權限被拒絕: ${_getPermissionName(permission)}');
      }
    } catch (e) {
      _addLog('❌ 請求權限時發生錯誤: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('權限請求失敗: $e')),
      );
    }
  }

  Future<void> _forceRequestAllPermissions() async {
    _addLog('=== 開始強制請求所有權限 ===');
    
    for (Permission permission in [Permission.camera, Permission.microphone, Permission.storage]) {
      await _requestPermission(permission);
      // 在請求之間稍作延遲
      await Future.delayed(Duration(milliseconds: 500));
    }
    
    _addLog('=== 強制權限請求完成 ===');
  }

  void _showSettingsDialog(Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('權限被拒絕'),
        content: Text('${_getPermissionName(permission)} 權限已被永久拒絕，請到設定中手動開啟。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
              _addLog('已開啟應用程式設定頁面');
            },
            child: Text('開啟設定'),
          ),
        ],
      ),
    );
  }

  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return '相機';
      case Permission.microphone:
        return '麥克風';
      case Permission.storage:
        return '儲存空間';
      default:
        return permission.toString();
    }
  }

  Color _getStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.orange;
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      case PermissionStatus.restricted:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '已授權 ✅';
      case PermissionStatus.denied:
        return '被拒絕 ⚠️';
      case PermissionStatus.permanentlyDenied:
        return '永久拒絕 ❌';
      case PermissionStatus.restricted:
        return '受限制 🔒';
      default:
        return '未知 ❓';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('iOS 權限調試'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 權限狀態區域
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '權限狀態',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                ..._permissionStatuses.entries.map((entry) {
                  Permission permission = entry.key;
                  PermissionStatus status = entry.value;
                  
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        permission == Permission.camera 
                          ? Icons.camera_alt 
                          : permission == Permission.microphone 
                            ? Icons.mic 
                            : Icons.storage,
                        color: _getStatusColor(status),
                      ),
                      title: Text(_getPermissionName(permission)),
                      subtitle: Text(_getStatusText(status)),
                      trailing: ElevatedButton(
                        onPressed: status == PermissionStatus.granted 
                          ? null 
                          : () => _requestPermission(permission),
                        child: Text('請求'),
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: 16),
                // 操作按鈕
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _checkAllPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('重新檢查'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _forceRequestAllPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('強制請求'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => openAppSettings(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('開啟應用程式設定'),
                ),
              ],
            ),
          ),
          // 分隔線
          Divider(),
          // 調試日誌區域
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '調試日誌',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _debugLogs.clear();
                          });
                        },
                        child: Text('清除'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ListView.builder(
                        itemCount: _debugLogs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _debugLogs[index],
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
