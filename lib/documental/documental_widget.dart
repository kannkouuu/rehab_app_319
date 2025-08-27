import '../main.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'documental_model.dart';
export 'documental_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';

class DocumentalWidget extends StatefulWidget {
  const DocumentalWidget({Key? key}) : super(key: key);

  @override
  _DocumentalWidgetState createState() => _DocumentalWidgetState();
}

class _DocumentalWidgetState extends State<DocumentalWidget> {
  late DocumentalModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();

  // 新增篩選狀態變數
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _filterPart = '全部';
  String _filterAction = '';
  List<dynamic>? _originalData;
  List<dynamic>? _filteredData;
  
  // 新增：用於儲存 Future 的變數，避免重複調用
  Future<List>? _dataFuture;
  bool _isInitialized = false;

  Future<List> getData() async {
    var url = Uri.parse(ip + "getdata1.php");
    final responce = await http.post(url, body: {
      "account": FFAppState().accountnumber,
      "action": "", // 移除搜尋條件，改為在前端篩選
    });
    final data = jsonDecode(responce.body);
    _originalData = data;

    // 如果有篩選條件，立即應用篩選
    if (_hasActiveFilters()) {
      _filteredData = _applyFilters(data);
    } else {
      _filteredData = null; // 清除篩選結果
    }

    return data;
  }

  // 新增：初始化數據載入
  void _initializeData() {
    if (!_isInitialized) {
      _dataFuture = getData();
      _isInitialized = true;
    }
  }

  // 新增：重新載入數據
  void _refreshData() {
    setState(() {
      _dataFuture = getData();
    });
  }

  // 新增篩選函數
  List<dynamic> _applyFilters(List<dynamic> data) {
    if (data.isEmpty) return data;

    return data.where((item) {
      // 日期篩選
      if (_filterStartDate != null || _filterEndDate != null) {
        final timeString = item['time']?.toString() ?? '';
        try {
          final itemDate = DateTime.parse(timeString.substring(0, 10));

          if (_filterStartDate != null) {
            if (itemDate.isBefore(_filterStartDate!)) {
              return false;
            }
          }

          if (_filterEndDate != null) {
            if (itemDate.isAfter(_filterEndDate!)) {
              return false;
            }
          }
        } catch (e) {
          // 如果日期解析失敗，跳過此項目
          return false;
        }
      }

      // 部位篩選
      if (_filterPart != '全部') {
        final parts = item['parts']?.toString() ?? '';

        // 特殊處理：復健成效測驗
        if (_filterPart == '復健成效測驗') {
          final degree = item['degree']?.toString() ?? '';
          if (!(degree == '測試' && parts == '吞嚥')) {
            return false;
          }
        } else {
          if (parts != _filterPart) {
            return false;
          }
        }
      }

      // 訓練動作關鍵字篩選
      if (_filterAction.isNotEmpty) {
        final action = item['action']?.toString() ?? '';
        if (!action.toLowerCase().contains(_filterAction.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // 新增重置篩選函數
  void _resetFilters() {
    setState(() {
      _filterStartDate = null;
      _filterEndDate = null;
      _filterPart = '全部';
      _filterAction = '';
      _filteredData = null;
    });
  }

  // 檢查是否有啟用的篩選條件
  bool _hasActiveFilters() {
    return _filterStartDate != null ||
        _filterEndDate != null ||
        _filterPart != '全部' ||
        _filterAction.isNotEmpty;
  }

  // 建立篩選條件的Chip顯示
  List<Widget> _buildFilterChips() {
    List<Widget> chips = [];

    if (_filterStartDate != null || _filterEndDate != null) {
      String dateText = '';
      if (_filterStartDate != null && _filterEndDate != null) {
        dateText =
            '日期: ${DateFormat('MM/dd').format(_filterStartDate!)} - ${DateFormat('MM/dd').format(_filterEndDate!)}';
      } else if (_filterStartDate != null) {
        dateText = '起始: ${DateFormat('MM/dd').format(_filterStartDate!)}';
      } else if (_filterEndDate != null) {
        dateText = '結束: ${DateFormat('MM/dd').format(_filterEndDate!)}';
      }

      chips.add(Chip(
        label: Text(dateText, style: TextStyle(fontSize: 12)),
        backgroundColor: Colors.blue.shade50,
        labelStyle: TextStyle(color: Colors.blue.shade700),
        deleteIcon: Icon(Icons.close, size: 16),
        onDeleted: () {
          setState(() {
            _filterStartDate = null;
            _filterEndDate = null;
            if (_originalData != null) {
              _filteredData = _applyFilters(_originalData!);
            }
          });
        },
      ));
    }

    if (_filterPart != '全部') {
      chips.add(Chip(
        label: Text(_filterPart, style: TextStyle(fontSize: 12)),
        backgroundColor: Colors.green.shade50,
        labelStyle: TextStyle(color: Colors.green.shade700),
        deleteIcon: Icon(Icons.close, size: 16),
        onDeleted: () {
          setState(() {
            _filterPart = '全部';
            if (_originalData != null) {
              _filteredData = _applyFilters(_originalData!);
            }
          });
        },
      ));
    }

    if (_filterAction.isNotEmpty) {
      chips.add(Chip(
        label: Text('關鍵字: $_filterAction', style: TextStyle(fontSize: 12)),
        backgroundColor: Colors.purple.shade50,
        labelStyle: TextStyle(color: Colors.purple.shade700),
        deleteIcon: Icon(Icons.close, size: 16),
        onDeleted: () {
          setState(() {
            _filterAction = '';
            if (_originalData != null) {
              _filteredData = _applyFilters(_originalData!);
            }
          });
        },
      ));
    }

    return chips;
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DocumentalModel());
    _model.searchBarController ??= TextEditingController();
    
    // 初始化數據載入
    _initializeData();
  }

  @override
  void dispose() {
    _model.dispose();

    _unfocusNode.dispose();
    super.dispose();
  }

  Future<void> _showSearchDialog() async {
    DateTime? _selectedStartDate = _filterStartDate;
    DateTime? _selectedEndDate = _filterEndDate;
    String _selectedPart = _filterPart;
    String _tempAction = _filterAction;

    final parts = ['全部', '上肢', '下肢', '吞嚥', '復健成效測驗'];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        // 使用局部變數而不是controller
        final actionController = TextEditingController(text: _tempAction);

        return PopScope(
          canPop: true,
          onPopInvoked: (didPop) async {
            if (didPop) {
              // 關閉鍵盤
              FocusScope.of(dialogContext).unfocus();
              // 安全釋放controller
              await Future.delayed(Duration(milliseconds: 100));
              actionController.dispose();
            }
          },
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
              side: BorderSide(
                  color: FlutterFlowTheme.of(context).primary, width: 2),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            actionsPadding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            actionsAlignment: MainAxisAlignment.center,
            title: Text('篩選與搜尋',
                style: FlutterFlowTheme.of(context).headlineSmall),
            content: StatefulBuilder(
              builder: (context, setDialogState) {
                Future<void> _pickDate(bool isStartDate) async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    locale: Locale('zh', 'TW'),
                    initialDate:
                        (isStartDate ? _selectedStartDate : _selectedEndDate) ??
                            DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                    helpText: isStartDate ? '選擇開始日期' : '選擇結束日期',
                    cancelText: '取消',
                    confirmText: '確認',
                  );
                  if (pickedDate != null) {
                    setDialogState(() {
                      if (isStartDate) {
                        _selectedStartDate = pickedDate;
                      } else {
                        _selectedEndDate = pickedDate;
                      }
                    });
                  }
                }

                Widget _buildSectionTitle(String title) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: Text(
                      title,
                      style: FlutterFlowTheme.of(context).titleSmall.override(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                    ),
                  );
                }

                Widget _buildDatePickerField({
                  required String label,
                  required DateTime? selectedDate,
                  required VoidCallback onPickDate,
                }) {
                  return InkWell(
                    onTap: onPickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label,
                              style: FlutterFlowTheme.of(context).bodyMedium),
                          Row(
                            children: [
                              Text(
                                selectedDate == null
                                    ? '請選擇日期'
                                    : DateFormat('yyyy/MM/dd')
                                        .format(selectedDate),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Poppins',
                                      color: selectedDate == null
                                          ? Colors.grey.shade600
                                          : FlutterFlowTheme.of(context)
                                              .primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.calendar_month_outlined,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSectionTitle('日期範圍'),
                      _buildDatePickerField(
                        label: '開始日期',
                        selectedDate: _selectedStartDate,
                        onPickDate: () => _pickDate(true),
                      ),
                      SizedBox(height: 8),
                      _buildDatePickerField(
                        label: '結束日期',
                        selectedDate: _selectedEndDate,
                        onPickDate: () => _pickDate(false),
                      ),
                      Divider(height: 32, thickness: 1),
                      _buildSectionTitle('部位'),
                      DropdownButtonFormField<String>(
                        value: _selectedPart,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                        dropdownColor: Colors.white,
                        items: parts.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setDialogState(() {
                            _selectedPart = newValue!;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      Divider(height: 32, thickness: 1),
                      _buildSectionTitle('訓練動作 (關鍵字)'),
                      TextFormField(
                        controller: actionController,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                        decoration: InputDecoration(
                          hintText: '例如：抬腿、握拳...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  children: [
                    Divider(
                      thickness: 1,
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                            },
                            child: Text('取消'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext, {
                                'startDate': _selectedStartDate,
                                'endDate': _selectedEndDate,
                                'part': _selectedPart,
                                'action': actionController.text.trim(),
                              });
                            },
                            child: Text('套用篩選'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  FlutterFlowTheme.of(context).primary,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    // 處理對話框返回的結果
    if (result != null) {
      setState(() {
        _filterStartDate = result['startDate'];
        _filterEndDate = result['endDate'];
        _filterPart = result['part'];
        _filterAction = result['action'];

        // 應用篩選
        if (_originalData != null) {
          _filteredData = _applyFilters(_originalData!);
        }
      });
    }
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
    final searchBarHeight =
        isLandscape ? screenHeight * 0.1 : screenHeight * 0.07;

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
                      '使用紀錄',
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
                      onPressed: _showSearchDialog,
                      icon: Icon(_hasActiveFilters()
                          ? Icons.filter_alt
                          : Icons.filter_list),
                      label: Text(
                          _hasActiveFilters() ? '已套用篩選 (點擊修改)' : '篩選與搜尋紀錄'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: _hasActiveFilters()
                            ? Colors.orange
                            : FlutterFlowTheme.of(context).primary,
                        minimumSize: Size(double.infinity, searchBarHeight),
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
                    if (_hasActiveFilters())
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
                child: FutureBuilder<List>(
                  future: _dataFuture, // 使用儲存的 Future，避免重複調用
                  builder: (ctx, ss) {
                    if (ss.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (ss.hasError) {
                      return Center(child: Text('載入錯誤: ${ss.error}'));
                    }

                    // 使用篩選後的資料，如果沒有篩選則使用原始資料
                    final displayData = _filteredData ?? ss.data;
                    return Items(list: displayData, isLandscape: isLandscape);
                  },
                ),
              ),
              BottomNavigation(currentPage: 'documental'),
            ],
          ),
        ),
      ),
    );
  }
}

class Items extends StatelessWidget {
  final List? list;
  final bool isLandscape;

  const Items({Key? key, this.list, required this.isLandscape})
      : super(key: key);

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

  Map<String, List<dynamic>> _groupDataByDate(List<dynamic> data) {
    final Map<String, List<dynamic>> groupedData = {};
    for (var item in data) {
      String date = _extractDate(item['time'].toString());
      if (groupedData[date] == null) {
        groupedData[date] = [];
      }
      groupedData[date]!.add(item);
    }
    return groupedData;
  }

  IconData _getIconForPart(String? part) {
    switch (part) {
      case '上肢':
        return Icons.sports_handball;
      case '下肢':
        return Icons.directions_walk;
      case '吞嚥':
        return Icons.face;
      default:
        return Icons.fitness_center;
    }
  }

  List<Widget> _buildChipWidgets(
    BuildContext context, {
    required String degree,
    required String parts,
    required bool isSwallowTest,
    required bool hidePrimarySwallowChip,
    required bool isLandscape,
  }) {
    final chipFontSize = isLandscape
        ? MediaQuery.of(context).size.height * 0.022
        : MediaQuery.of(context).size.width * 0.03;

    if (isSwallowTest) {
      return [
        Chip(
          label: Text('復健成效測驗'),
          backgroundColor: Colors.white,
          shape: StadiumBorder(
              side: BorderSide(color: Colors.blue.shade700, width: 1.5)),
          labelStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Poppins',
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
                fontSize: chipFontSize,
              ),
        )
      ];
    }

    final List<Widget> chips = [];

    if (degree.isNotEmpty && !hidePrimarySwallowChip) {
      Color textColor;
      Color borderColor;

      switch (degree) {
        case '初階':
          textColor = Colors.green.shade800;
          borderColor = Colors.green.shade800;
          break;
        case '進階':
          textColor = Colors.red.shade800;
          borderColor = Colors.red.shade800;
          break;
        default:
          textColor = Colors.black87;
          borderColor = Colors.grey;
      }

      chips.add(Chip(
        label: Text(degree),
        backgroundColor: Colors.white,
        shape: StadiumBorder(side: BorderSide(color: borderColor, width: 1.5)),
        labelStyle: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'Poppins',
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: chipFontSize,
            ),
      ));
    }

    if (parts.isNotEmpty) {
      if (chips.isNotEmpty) {
        chips.add(SizedBox(width: 5));
      }
      chips.add(Chip(
        label: Text(parts),
        backgroundColor: Color(0xFFE0E3E7),
        labelStyle: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'Poppins',
              color: Colors.black87,
              fontSize: chipFontSize,
            ),
      ));
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    if (list == null || list!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              '沒有找到相關紀錄',
              style: TextStyle(
                fontSize: isLandscape
                    ? MediaQuery.of(context).size.height * 0.04
                    : MediaQuery.of(context).size.width * 0.045,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final List<dynamic> displayList = list!.reversed.toList();
    final groupedData = _groupDataByDate(displayList);
    final dates = groupedData.keys.toList();

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
                    _buildRecordCard(context, item as Map<String, dynamic>))
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildRecordCard(BuildContext context, Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final titleFontSize =
        isLandscape ? screenHeight * 0.03 : screenWidth * 0.04;
    final detailsFontSize =
        isLandscape ? screenHeight * 0.023 : screenWidth * 0.032;

    final String degree = item['degree']?.toString() ?? '';
    final String parts = item['parts']?.toString() ?? '';
    final String action = item['action']?.toString() ?? '';

    final bool isVocalPractice = action == '發音練習';
    final bool isRsstTest = action == 'RSST';
    final bool isSwallowTest = degree == '測試' && parts == '吞嚥';
    final bool hidePrimarySwallowChip = degree == '初階' && parts == '吞嚥';

    Widget buildVocalPracticeDetails() {
      String pa = '0', ta = '0', ka = '0';
      final paTaKaData = item['PA_TA_KA']?.toString();
      if (paTaKaData != null && paTaKaData.isNotEmpty) {
        final parts = paTaKaData.split('/');
        if (parts.length == 3) {
          pa = parts[0].trim();
          ta = parts[1].trim();
          ka = parts[2].trim();
        }
      }
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          'PA：$pa, TA：$ta, KA：$ka',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Poppins',
                color: Color(0xFF57636C),
                fontSize: detailsFontSize,
              ),
        ),
      );
    }

    Widget buildRsstTestDetails() {
      String testTimes = '0';
      final rsstTestTimesData = item['rsst_test_times']?.toString();
      if (rsstTestTimesData != null && rsstTestTimesData.isNotEmpty) {
        testTimes = rsstTestTimesData.trim();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          '次數：$testTimes',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Poppins',
                color: Color(0xFF57636C),
                fontSize: detailsFontSize,
              ),
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
                color: FlutterFlowTheme.of(context).primary, width: 5),
          ),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                _getIconForPart(item['parts']?.toString()),
                color: FlutterFlowTheme.of(context).primary,
                size: isLandscape ? 30 : 26,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      action,
                      style: FlutterFlowTheme.of(context).titleLarge.override(
                            fontFamily: 'Poppins',
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isVocalPractice) buildVocalPracticeDetails(),
                    if (isRsstTest) buildRsstTestDetails(),
                  ],
                ),
              ),
              SizedBox(width: 8),
              ..._buildChipWidgets(
                context,
                degree: degree,
                parts: parts,
                isSwallowTest: isSwallowTest,
                hidePrimarySwallowChip: hidePrimarySwallowChip,
                isLandscape: isLandscape,
              )
            ],
          ),
        ),
      ),
    );
  }
}
