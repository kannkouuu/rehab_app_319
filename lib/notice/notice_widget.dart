import 'dart:convert';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'notice_model.dart';
export 'notice_model.dart';
import 'package:http/http.dart' as http;
import '/main.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class NoticeWidget extends StatefulWidget {
  const NoticeWidget({Key? key}) : super(key: key);

  @override
  _NoticeWidgetState createState() => _NoticeWidgetState();
}

class _NoticeWidgetState extends State<NoticeWidget> {
  late NoticeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();

  // 篩選狀態變數
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedStatus = '全部';
  List<dynamic> _originalData = [];
  List<dynamic> _filteredData = [];
  bool _isFiltered = false;

  // 新增：將 Future 作為狀態變數儲存，避免重複呼叫
  Future<List>? _dataFuture;

  Future<List> _fetchData() async {
    var url = Uri.parse(ip + "getdata2.php");
    final responce = await http.post(url, body: {
      "account": FFAppState().accountnumber,
      "time": "", // 移除搜尋框，改為空字串
    });

    final data = jsonDecode(responce.body);
    _originalData = data;
    _applyFilters();
    return _filteredData;
  }

  // 初始化資料獲取
  void _initializeData() {
    _dataFuture = _fetchData();
  }

  // 更新已讀狀態的API調用
  Future<bool> updateReadStatus(String noticeId) async {
    try {
      var url = Uri.parse(ip + "update_read_status.php");
      final response = await http.post(url, body: {
        "notice_id": noticeId,
        "account": FFAppState().accountnumber,
      });

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      }
      return false;
    } catch (e) {
      print('更新已讀狀態失敗: $e');
      return false;
    }
  }

  void _applyFilters() {
    List<dynamic> filtered = List.from(_originalData);

    // 為每個項目添加原始索引
    for (int i = 0; i < filtered.length; i++) {
      if (filtered[i] is Map<String, dynamic>) {
        filtered[i]['_originalIndex'] = i;
      }
    }

    // 日期篩選
    if (_startDate != null || _endDate != null) {
      filtered = filtered.where((item) {
        try {
          String timeString = item['time'].toString();
          DateTime itemDate = DateTime.parse(timeString.substring(0, 10));

          if (_startDate != null && itemDate.isBefore(_startDate!)) {
            return false;
          }
          if (_endDate != null && itemDate.isAfter(_endDate!)) {
            return false;
          }
          return true;
        } catch (e) {
          return true;
        }
      }).toList();
    }

    // 已讀/未讀狀態篩選 - 使用資料表中的read_yet欄位
    if (_selectedStatus != '全部') {
      filtered = filtered.where((item) {
        final readYet = item['read_yet'];
        final bool isRead = readYet == '1' || readYet == 1;

        if (_selectedStatus == '已讀') {
          return isRead;
        } else if (_selectedStatus == '未讀') {
          return !isRead;
        }
        return true;
      }).toList();
    }

    // 按時間倒序排列（最新的在最前面）
    filtered.sort((a, b) {
      try {
        String timeA = a['time'].toString();
        String timeB = b['time'].toString();
        DateTime dateTimeA = DateTime.parse(timeA);
        DateTime dateTimeB = DateTime.parse(timeB);
        return dateTimeB.compareTo(dateTimeA); // 倒序排列
      } catch (e) {
        return 0;
      }
    });

    _filteredData = filtered;
    _isFiltered =
        _startDate != null || _endDate != null || _selectedStatus != '全部';
  }

  // 重新獲取資料的方法
  void _refreshData() {
    setState(() {
      _dataFuture = _fetchData();
    });
  }

  // 僅更新本地資料而不重新獲取的方法
  void _updateLocalData() {
    setState(() {
      _applyFilters();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PopScope(
          onPopInvoked: (bool didPop) {
            if (didPop) {
              FocusScope.of(context).unfocus();
            }
          },
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                backgroundColor: Colors.white,
                title: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list,
                          color: FlutterFlowTheme.of(context).primary),
                      SizedBox(width: 8),
                      Text(
                        '篩選與搜尋通知',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                content: Container(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 日期範圍區塊
                      Text(
                        '日期範圍',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  locale: Locale('zh', 'TW'),
                                  helpText: '選擇開始日期',
                                  cancelText: '取消',
                                  confirmText: '確認',
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    _startDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _startDate != null
                                      ? FlutterFlowTheme.of(context)
                                          .primary
                                          .withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _startDate != null
                                        ? FlutterFlowTheme.of(context).primary
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 16,
                                        color: _startDate != null
                                            ? FlutterFlowTheme.of(context)
                                                .primary
                                            : Colors.grey[600]),
                                    SizedBox(width: 8),
                                    Text(
                                      _startDate != null
                                          ? DateFormat('yyyy/MM/dd')
                                              .format(_startDate!)
                                          : '開始日期',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _startDate != null
                                            ? FlutterFlowTheme.of(context)
                                                .primary
                                            : Colors.grey[600],
                                        fontWeight: _startDate != null
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('至', style: TextStyle(color: Colors.grey[600])),
                          SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  locale: Locale('zh', 'TW'),
                                  helpText: '選擇結束日期',
                                  cancelText: '取消',
                                  confirmText: '確認',
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    _endDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _endDate != null
                                      ? FlutterFlowTheme.of(context)
                                          .primary
                                          .withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _endDate != null
                                        ? FlutterFlowTheme.of(context).primary
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 16,
                                        color: _endDate != null
                                            ? FlutterFlowTheme.of(context)
                                                .primary
                                            : Colors.grey[600]),
                                    SizedBox(width: 8),
                                    Text(
                                      _endDate != null
                                          ? DateFormat('yyyy/MM/dd')
                                              .format(_endDate!)
                                          : '結束日期',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _endDate != null
                                            ? FlutterFlowTheme.of(context)
                                                .primary
                                            : Colors.grey[600],
                                        fontWeight: _endDate != null
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),
                      Divider(color: Colors.grey[300]),
                      SizedBox(height: 16),

                      // 狀態區塊
                      Text(
                        '通知狀態',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          isExpanded: true,
                          underline: SizedBox(),
                          dropdownColor: Colors.white,
                          style: TextStyle(color: Colors.black87, fontSize: 16),
                          items: ['全部', '已讀', '未讀'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              _selectedStatus = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Divider(color: Colors.grey[300]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('取消',
                            style: TextStyle(color: Colors.grey[600])),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final result = {
                            'startDate': _startDate,
                            'endDate': _endDate,
                            'status': _selectedStatus,
                          };
                          Navigator.of(context).pop(result);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlutterFlowTheme.of(context).primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child:
                            Text('套用篩選', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    ).then((result) {
      if (result != null) {
        _startDate = result['startDate'];
        _endDate = result['endDate'];
        _selectedStatus = result['status'];
        // 僅更新本地資料而不重新獲取
        _updateLocalData();
      }
    });
  }

  void _clearFilter(String filterType) {
    switch (filterType) {
      case 'startDate':
        _startDate = null;
        break;
      case 'endDate':
        _endDate = null;
        break;
      case 'status':
        _selectedStatus = '全部';
        break;
    }
    _updateLocalData();
  }

  // 建立篩選條件的Chip顯示
  List<Widget> _buildFilterChips() {
    List<Widget> chips = [];

    if (_startDate != null || _endDate != null) {
      String dateText = '';
      if (_startDate != null && _endDate != null) {
        dateText =
            '日期: ${DateFormat('MM/dd').format(_startDate!)} - ${DateFormat('MM/dd').format(_endDate!)}';
      } else if (_startDate != null) {
        dateText = '起始: ${DateFormat('MM/dd').format(_startDate!)}';
      } else if (_endDate != null) {
        dateText = '結束: ${DateFormat('MM/dd').format(_endDate!)}';
      }

      chips.add(Chip(
        label: Text(dateText, style: TextStyle(fontSize: 12)),
        backgroundColor: Colors.blue.shade50,
        labelStyle: TextStyle(color: Colors.blue.shade700),
        deleteIcon: Icon(Icons.close, size: 16),
        onDeleted: () {
          _startDate = null;
          _endDate = null;
          _updateLocalData();
        },
      ));
    }

    if (_selectedStatus != '全部') {
      chips.add(Chip(
        label: Text(_selectedStatus, style: TextStyle(fontSize: 12)),
        backgroundColor: Colors.green.shade50,
        labelStyle: TextStyle(color: Colors.green.shade700),
        deleteIcon: Icon(Icons.close, size: 16),
        onDeleted: () {
          _selectedStatus = '全部';
          _updateLocalData();
        },
      ));
    }

    return chips;
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NoticeModel());

    // 進入通知頁面時，標記通知為已檢查（清除紅點）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FFAppState().markNotificationsAsChecked();
      }
    });

    // 初始化資料獲取
    _initializeData();
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
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final titleFontSize =
        isLandscape ? screenHeight * 0.06 : screenWidth * 0.07;

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_unfocusNode),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        key: scaffoldKey,
        backgroundColor: Color(0xFF90BDF9), // 與關於頁面相同的背景色
        body: SafeArea(
          top: true,
          bottom: false, // 關閉底部安全區域，讓導航欄可以貼合底部
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fixed Header Area
              Container(
                width: double.infinity,
                height: isLandscape ? screenHeight * 0.15 : screenHeight * 0.1,
                color: Color(0xFF90BDF9),
                padding: EdgeInsets.symmetric(
                    vertical: isLandscape
                        ? screenHeight * 0.01
                        : screenHeight * 0.01),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '新通知',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).displaySmall.override(
                            fontFamily: 'Poppins',
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showFilterDialog,
                      icon: Icon(
                          _isFiltered ? Icons.filter_alt : Icons.filter_list),
                      label: Text(_isFiltered ? '已套用篩選 (點擊修改)' : '篩選與搜尋通知'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: _isFiltered
                            ? Colors.orange
                            : FlutterFlowTheme.of(context).primary,
                        minimumSize: Size(
                            double.infinity,
                            isLandscape
                                ? screenHeight * 0.1
                                : screenHeight * 0.07),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        textStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: isLandscape
                              ? screenHeight * 0.03
                              : screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_isFiltered)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: _buildFilterChips(),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _refreshData();
                    // 等待新的 Future 完成
                    await _dataFuture;
                  },
                  child: FutureBuilder<List>(
                    future: _dataFuture,
                    builder: (ctx, ss) {
                      if (ss.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (ss.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 80, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text('載入錯誤: ${ss.error}',
                                  style: TextStyle(color: Colors.grey[600])),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshData,
                                child: Text('重新載入'),
                              ),
                            ],
                          ),
                        );
                      }
                      return Items(
                        list: ss.data,
                        isLandscape: isLandscape,
                        onMessageRead: (Map<String, dynamic> item) async {
                          // 只有未讀訊息才需要更新
                          final readYet = item['read_yet'];
                          final bool isRead = readYet == '1' || readYet == 1;

                          if (!isRead) {
                            final success =
                                await updateReadStatus(item['id'].toString());
                            if (success) {
                              // 更新本地數據，避免重新獲取資料
                              // 更新原始數據中的read_yet狀態
                              for (var originalItem in _originalData) {
                                if (originalItem['id'] == item['id']) {
                                  originalItem['read_yet'] = '1';
                                  break;
                                }
                              }
                              // 僅更新本地資料而不重新獲取
                              _updateLocalData();
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ),

              // Fixed Bottom Navigation Bar
              BottomNavigation(currentPage: 'notice'),
            ],
          ),
        ),
      ),
    );
  }
}

class Items extends StatefulWidget {
  final List? list;
  final bool isLandscape;
  final Function(Map<String, dynamic>) onMessageRead;

  Items({
    this.list,
    required this.isLandscape,
    required this.onMessageRead,
  });

  @override
  State<Items> createState() => _ItemsState();
}

class _ItemsState extends State<Items> {
  String _extractDate(String timeString) {
    try {
      if (timeString.length >= 10) {
        return timeString.substring(0, 10);
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  String _extractTime(String timeString) {
    try {
      if (timeString.length > 11) {
        return timeString.substring(11, 16); // HH:mm
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Map<String, List<dynamic>> _groupDataByDate(List<dynamic> data) {
    final Map<String, List<dynamic>> groupedData = {};
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final augmentedItem = Map<String, dynamic>.from(item);
      augmentedItem['_originalIndex'] = i;

      String date = _extractDate(item['time'].toString());
      if (groupedData[date] == null) {
        groupedData[date] = [];
      }
      groupedData[date]!.add(augmentedItem);
    }

    // 對每個日期分組內的通知按時間倒序排列
    groupedData.forEach((date, items) {
      items.sort((a, b) {
        try {
          String timeA = a['time'].toString();
          String timeB = b['time'].toString();
          DateTime dateTimeA = DateTime.parse(timeA);
          DateTime dateTimeB = DateTime.parse(timeB);
          return dateTimeB.compareTo(dateTimeA); // 倒序排列
        } catch (e) {
          return 0;
        }
      });
    });

    return groupedData;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.list == null || widget.list!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              '沒有任何通知',
              style: TextStyle(
                fontSize: widget.isLandscape
                    ? MediaQuery.of(context).size.height * 0.04
                    : MediaQuery.of(context).size.width * 0.045,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final groupedData = _groupDataByDate(widget.list!);
    final dates = groupedData.keys.toList();

    // 將日期按倒序排列（最新的日期在最前面）
    dates.sort((a, b) {
      try {
        DateTime dateA = DateTime.parse(a);
        DateTime dateB = DateTime.parse(b);
        return dateB.compareTo(dateA); // 倒序排列
      } catch (e) {
        return 0;
      }
    });

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 16),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final itemsForDate = groupedData[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 16, 8),
              child: Text(
                date,
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      fontFamily: 'Poppins',
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...itemsForDate
                .map((item) =>
                    _buildNoticeCard(context, item as Map<String, dynamic>))
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildNoticeCard(BuildContext context, Map<String, dynamic> item) {
    final bool isRead = item['read_yet'] == '1' || item['read_yet'] == 1;

    final titleFontSize = widget.isLandscape
        ? MediaQuery.of(context).size.height * 0.03
        : MediaQuery.of(context).size.width * 0.04;
    final subtitleFontSize = widget.isLandscape
        ? MediaQuery.of(context).size.height * 0.025
        : MediaQuery.of(context).size.width * 0.035;

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          // 先調用已讀狀態更新，再顯示對話框
          if (!isRead) {
            await widget.onMessageRead(item);
          }
          await showDialog(
            context: context,
            builder: (alertDialogContext) {
              return AlertDialog(
                title: Text(item['title'],
                    style: TextStyle(fontSize: titleFontSize * 1.2)),
                content: Text(item['content'],
                    style: TextStyle(fontSize: subtitleFontSize)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(alertDialogContext),
                    child: Text('Ok',
                        style: TextStyle(fontSize: subtitleFontSize)),
                  ),
                ],
              );
            },
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                  color: isRead
                      ? Colors.grey
                      : FlutterFlowTheme.of(context).primary,
                  width: 5),
            ),
            color: Colors.white,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            child: Row(
              children: [
                Icon(
                  isRead
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread_outlined,
                  color: isRead
                      ? Colors.grey
                      : FlutterFlowTheme.of(context).primary,
                  size: widget.isLandscape ? 30 : 26,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['title'],
                        style: FlutterFlowTheme.of(context)
                            .titleMedium
                            .override(
                              fontFamily: 'Poppins',
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: isRead ? Colors.black54 : Colors.black87,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_extractTime(item['time'])} - ${item['content']}',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Poppins',
                              color: Colors.grey[600],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
