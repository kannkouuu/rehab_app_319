import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionTestWidget extends StatefulWidget {
  @override
  _PermissionTestWidgetState createState() => _PermissionTestWidgetState();
}

class _PermissionTestWidgetState extends State<PermissionTestWidget> {
  Map<Permission, PermissionStatus> _permissionStatuses = {};

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    List<Permission> permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ];

    Map<Permission, PermissionStatus> statuses = {};
    for (Permission permission in permissions) {
      try {
        statuses[permission] = await permission.status;
      } catch (e) {
        print('檢查權限 $permission 時發生錯誤: $e');
        statuses[permission] = PermissionStatus.denied;
      }
    }

    setState(() {
      _permissionStatuses = statuses;
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    try {
      print('正在請求權限: $permission');
      PermissionStatus status = await permission.request();
      print('權限請求結果: $status');
      
      setState(() {
        _permissionStatuses[permission] = status;
      });

      if (status.isPermanentlyDenied) {
        _showSettingsDialog(permission);
      }
    } catch (e) {
      print('請求權限 $permission 時發生錯誤: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('權限請求失敗: $e')),
      );
    }
  }

  void _showSettingsDialog(Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('權限被拒絕'),
        content: Text('請到設定中手動開啟 ${_getPermissionName(permission)} 權限'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
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
        return '已授權';
      case PermissionStatus.denied:
        return '被拒絕';
      case PermissionStatus.permanentlyDenied:
        return '永久拒絕';
      case PermissionStatus.restricted:
        return '受限制';
      default:
        return '未知';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('權限測試'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkAllPermissions,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            '權限狀態檢查',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),
          ..._permissionStatuses.entries.map((entry) {
            Permission permission = entry.key;
            PermissionStatus status = entry.value;
            
            return Card(
              child: ListTile(
                title: Text(_getPermissionName(permission)),
                subtitle: Text('狀態: ${_getStatusText(status)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: status == PermissionStatus.granted 
                        ? null 
                        : () => _requestPermission(permission),
                      child: Text('請求'),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              print('=== 權限狀態總結 ===');
              _permissionStatuses.forEach((permission, status) {
                print('${_getPermissionName(permission)}: $status');
              });
            },
            child: Text('打印權限狀態到控制台'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            child: Text('開啟應用程式設定'),
          ),
        ],
      ),
    );
  }
}
