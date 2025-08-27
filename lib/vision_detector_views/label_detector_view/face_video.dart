import 'package:flutter/material.dart';
import 'package:rehab_app_319/trainmouth/trainmouth_widget.dart';
import 'package:video_player/video_player.dart';
import 'face_class.dart';

class FaceVideoApp extends StatefulWidget {
  const FaceVideoApp({super.key});

  @override
  _VideoAppState createState() => _VideoAppState();
}

class _VideoAppState extends State<FaceVideoApp> {
  late VideoPlayerController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  late String _videoUrl;
  int _retryCount = 0;
  final int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    int _facenumber = Face_Detect_Number;

    // 使用 GitHub repository 中的影片 URL
    _videoUrl =
        'https://raw.githubusercontent.com/hpds-lab/rehab_video/main/face_videos/1.mp4'; // 默認值
    if (_facenumber == 4) {
      _videoUrl =
          'https://raw.githubusercontent.com/hpds-lab/rehab_video/main/face_videos/4new.mp4';
    } else {
      _videoUrl =
          'https://raw.githubusercontent.com/hpds-lab/rehab_video/main/face_videos/${_facenumber}.mp4';
    }

    _loadVideo();
  }

  void _loadVideo() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 使用網路 URL 播放影片
    _controller = VideoPlayerController.networkUrl(Uri.parse(_videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isLoading = false;
        });
        _controller.play();
      }).catchError((error) {
        print('影片初始化錯誤: $error');
        if (_retryCount < _maxRetries) {
          _retryCount++;
          print('正在重試第 $_retryCount 次...');
          Future.delayed(Duration(seconds: 2), () {
            _loadVideo();
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = '影片載入失敗：網路連接問題';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('影片文件載入失敗：${_videoUrl}'),
                duration: Duration(seconds: 3),
                action: SnackBarAction(
                  label: '重試',
                  onPressed: () {
                    _retryCount = 0;
                    _loadVideo();
                  },
                ),
              ),
            );
          }
        }
      });
  }

  void _retryLoad() {
    _retryCount = 0;
    _loadVideo();
  }

  // void _showInfoDialog(BuildContext context) {
  //   String title = "";
  //   String description = "";
  //   String imagePath = "";
  //   final screenSize = MediaQuery.of(context).size;
  //   final isLandscape =
  //       MediaQuery.of(context).orientation == Orientation.landscape;
  //   final dialogWidth =
  //       isLandscape ? screenSize.width * 0.7 : screenSize.width * 0.9;
  //   final dialogHeight =
  //       isLandscape ? screenSize.height * 0.8 : screenSize.height * 0.7;
  //   final titleFontSize =
  //       isLandscape ? screenSize.height * 0.04 : screenSize.width * 0.06;
  //   final descFontSize =
  //       isLandscape ? screenSize.height * 0.025 : screenSize.width * 0.04;
  //   final imgMaxHeight =
  //       isLandscape ? screenSize.height * 0.3 : screenSize.height * 0.25;

  //   switch (Face_Detect_Number) {
  //     case 9:
  //       title = "語言訓練";
  //       description =
  //           "此訓練主要針對語言功能障礙患者，透過發音練習和語言復健活動，幫助恢復言語能力。訓練過程中需要反覆練習口部肌肉的協調運動，同時結合發聲訓練。\n\n訓練步驟：\n1. 坐直身體，放鬆肩膀\n2. 深呼吸後開始練習發音\n3. 從簡單的單音節開始，逐漸增加複雜度\n4. 每天練習10-15分鐘，每次訓練間隔足夠休息時間";
  //       imagePath = "assets/rehab_images/speech_muscles.png";
  //       break;
  //     case 10:
  //       title = "頭部轉動";
  //       description =
  //           "頭部轉動訓練可以幫助改善頸部肌肉的靈活性和力量，並促進血液循環。此訓練對於中風後頸部肌肉僵硬的患者特別有益。\n\n訓練步驟：\n1. 坐姿挺直，雙手放鬆\n2. 緩慢將頭部向左轉動，停留3-5秒\n3. 回到中間位置，再向右轉動，停留3-5秒\n4. 重複動作5-10次，注意動作要緩慢且控制良好";
  //       imagePath = "assets/rehab_images/head_turn_muscles.png";
  //       break;
  //     case 11:
  //       title = "肩部活動";
  //       description =
  //           "肩部活動訓練有助於恢復肩膀關節靈活度和肌肉力量，對於上肢功能障礙的中風患者非常重要。此訓練可預防肩部痛症和關節僵硬。\n\n訓練步驟：\n1. 坐直或站立，雙手放在頭上\n2. 將雙肩向上提升，保持5秒\n3. 放鬆後，嘗試向後和向前轉動肩膀\n4. 每種動作重複10次，動作要平穩且有控制";
  //       imagePath = "assets/rehab_images/shoulder_muscles.png";
  //       break;
  //     case 12:
  //       title = "唾液腺按摩";
  //       description =
  //           "唾液腺按摩可以刺激唾液分泌，幫助中風患者改善口乾和吞嚥困難的問題。此按摩也有助於面部血液循環和放鬆面部肌肉。\n\n訓練步驟：\n1. 用指腹在耳朵前方的腮腺區域輕輕畫圓\n2. 按摩下巴下方的顎下腺區域\n3. 按摩舌下腺位置（舌頭下方）\n4. 每個部位按摩30秒至1分鐘，每天進行2-3次";
  //       imagePath = "assets/rehab_images/salivary_gland_muscles.png";
  //       break;
  //     case 13:
  //       title = "臉頰鼓氣";
  //       description =
  //           "臉頰鼓氣訓練有助於加強臉頰肌肉和口腔控制能力，對吞嚥和發音有正面幫助。此訓練也可以改善面部對稱性。\n\n訓練步驟：\n1. 深吸一口氣，將空氣存在口腔中，鼓起臉頰\n2. 保持鼓氣姿勢5-10秒\n3. 緩慢呼出空氣\n4. 嘗試將空氣在左右臉頰間移動\n5. 重複以上動作8-10次";
  //       imagePath = "assets/rehab_images/puff_muscles.png";
  //       break;
  //     case 14:
  //       title = "舌頭壓舌板";
  //       description =
  //           "舌頭壓舌板訓練可以增強舌頭的力量和控制能力，對於改善吞嚥功能和說話清晰度有很大幫助。此訓練針對舌頭肌肉。\n\n訓練步驟：\n1. 將舌頭伸出抵住壓舌板\n2. 用舌頭施力推動壓舌板5-10秒\n3. 嘗試向不同方向推動（上、下、左、右）\n4. 每個方向重複5次\n5. 隨著能力增強，可以增加抵抗的時間";
  //       imagePath = "assets/rehab_images/tongue_depresser_muscles.png";
  //       break;
  //     default:
  //       title = "復健資訊";
  //       description = "請選擇特定的復健動作查看詳細說明。";
  //       imagePath = "";
  //   }

  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Dialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20.0),
  //         ),
  //         child: Container(
  //           width: dialogWidth,
  //           height: dialogHeight,
  //           padding: EdgeInsets.all(20),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Expanded(
  //                     child: Text(
  //                       title,
  //                       style: TextStyle(
  //                         fontSize: titleFontSize,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //                   ),
  //                   IconButton(
  //                     icon: Icon(Icons.close),
  //                     onPressed: () {
  //                       Navigator.of(context).pop();
  //                     },
  //                   ),
  //                 ],
  //               ),
  //               Divider(thickness: 2),
  //               Expanded(
  //                 child: SingleChildScrollView(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       SizedBox(height: 10),
  //                       Text(
  //                         description,
  //                         style: TextStyle(
  //                           fontSize: descFontSize,
  //                           height: 1.5,
  //                         ),
  //                       ),
  //                       SizedBox(height: 20),
  //                       if (imagePath.isNotEmpty)
  //                         Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             Text(
  //                               "訓練肌肉區域：",
  //                               style: TextStyle(
  //                                 fontSize: descFontSize *
  //                                     1.1, // Slightly larger than description
  //                                 fontWeight: FontWeight.bold,
  //                               ),
  //                             ),
  //                             SizedBox(height: 10),
  //                             Center(
  //                               child: ConstrainedBox(
  //                                 constraints: BoxConstraints(
  //                                   maxHeight: imgMaxHeight,
  //                                 ),
  //                                 child: Image.asset(
  //                                   imagePath,
  //                                   fit: BoxFit.contain,
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final buttonSize =
        isLandscape ? screenSize.height * 0.14 : screenSize.width * 0.2;
    final buttonIconSize = buttonSize * 0.6;
    final instructionFontSize =
        isLandscape ? screenSize.height * 0.03 : screenSize.width * 0.05;
    final appBarButtonSize =
        isLandscape ? screenSize.height * 0.08 : screenSize.width * 0.1;

    List<Widget> appBarActions = [];
    // if (Face_Detect_Number > 8) {
    //   appBarActions.add(
    //     IconButton(
    //       icon: Icon(Icons.info_outline,
    //           color: Colors.white, size: appBarButtonSize * 0.7),
    //       onPressed: () {
    //         _showInfoDialog(context);
    //       },
    //     ),
    //   );
    // }

    final appBarWidget = AppBar(
      backgroundColor: Color.fromARGB(255, 144, 189, 249),
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back,
            color: Colors.white, size: appBarButtonSize * 0.7),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        "動作示範",
        style: TextStyle(
            color: Colors.white,
            fontSize: isLandscape
                ? screenSize.height * 0.05
                : screenSize.width * 0.055),
      ),
      centerTitle: true,
      actions: appBarActions,
    );

    Widget bodyContent;

    if (isLandscape) {
      bodyContent = Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Instruction Text
            Container(
              width: screenSize.width * 0.22,
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: Color.fromARGB(132, 255, 255, 255),
                borderRadius: BorderRadius.all(Radius.circular(15.0)),
              ),
              child: Text(
                "上方按鈕暫停與重播影片\n下方按鈕開始復健!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: instructionFontSize,
                  color: Colors.black,
                  height: 1.3,
                ),
              ),
            ),
            // Center: Video Player
            Container(
              width: screenSize.width * 0.5, // Restrict video width
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text('載入影片中...',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    )
                  : _controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 50),
                              SizedBox(height: 10),
                              Text(
                                '影片載入失敗',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _retryLoad,
                                child: Text('重新載入'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
            // Right: Buttons
            Container(
              width: screenSize.width * 0.20, // Width for buttons column
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      fixedSize: Size(buttonSize, buttonSize),
                      shape: CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                    child: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: buttonIconSize,
                        color: Colors.white),
                  ),
                  SizedBox(
                      height: screenSize.height * 0.05), // Responsive spacing
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      fixedSize: Size(buttonSize, buttonSize),
                      shape: CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      // Navigation logic remains the same
                      switch (Face_Detect_Number) {
                        case 1:
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (context) => smile()));
                          break;
                        case 2:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => tougue()));
                          break;
                        case 3:
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (context) => pout()));
                          break;
                        case 4:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => open_mouth()));
                          break;
                        case 5:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => flick_tougue()));
                          break;
                        case 6:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => pursed_lips()));
                          break;
                        case 7:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => headneck_bend()));
                          break;
                        case 8:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => chin_movement()));
                          break;
                        case 9:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => speech()));
                          break;
                        case 10:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => head_turn()));
                          break;
                        case 11:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Shoulder_activities()));
                          break;
                        case 12:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      Salivary_gland_massage()));
                          break;
                        case 13:
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (context) => puff()));
                          break;
                        case 14:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => tongue_depresser()));
                          break;
                      }
                    },
                    child: Icon(Icons.arrow_forward,
                        size: buttonIconSize, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Portrait layout (original structure with slight adjustments for consistency if any)
      bodyContent = Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isLoading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('載入影片中...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                )
              else if (_controller.value.isInitialized)
                Container(
                  width: double.infinity, // Portrait takes full width
                  child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller)),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 50),
                      SizedBox(height: 10),
                      Text(
                        '影片載入失敗',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _retryLoad,
                        child: Text('重新載入'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 15), // Original: isLandscape ? 20 : 15
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      fixedSize: Size(buttonSize, buttonSize),
                      shape: CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                    child: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: buttonIconSize,
                        color: Colors.white),
                  ),
                  SizedBox(width: 30), // Original: isLandscape ? 40 : 30
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      fixedSize: Size(buttonSize, buttonSize),
                      shape: CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      // Navigation logic remains the same
                      switch (Face_Detect_Number) {
                        case 1:
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (context) => smile()));
                          break;
                        case 2:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => tougue()));
                          break;
                        case 3:
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (context) => pout()));
                          break;
                        case 4:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => open_mouth()));
                          break;
                        case 5:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => flick_tougue()));
                          break;
                        case 6:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => pursed_lips()));
                          break;
                        case 7:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => headneck_bend()));
                          break;
                        case 8:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => chin_movement()));
                          break;
                        case 9:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => speech()));
                          break;
                        case 10:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => head_turn()));
                          break;
                        case 11:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Shoulder_activities()));
                          break;
                        case 12:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      Salivary_gland_massage()));
                          break;
                        case 13:
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (context) => puff()));
                          break;
                        case 14:
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => tongue_depresser()));
                          break;
                      }
                    },
                    child: Icon(Icons.arrow_forward,
                        size: buttonIconSize, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 15), // Original: isLandscape ? 20 : 15
              Container(
                width: screenSize.width *
                    0.8, // Original: isLandscape ? screenSize.width * 0.5 : screenSize.width * 0.8,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color.fromARGB(132, 255, 255, 255),
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
                child: Text(
                  "左邊按鈕暫停與重播影片\n右邊按鈕開始復健!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: instructionFontSize,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: appBarWidget,
      body: Container(
        color: Color.fromARGB(255, 144, 189, 249),
        padding: EdgeInsets.all(isLandscape ? screenSize.width * 0.025 : 16.0),
        child: bodyContent,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
