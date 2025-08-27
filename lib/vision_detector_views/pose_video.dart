import 'package:flutter/material.dart';
import 'package:rehab_app_319/vision_detector_views/pose_transform.dart';
import 'package:video_player/video_player.dart';
import 'pose_view.dart';

class VideoApp extends StatefulWidget {
  const VideoApp({super.key});

  @override
  _VideoAppState createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  late VideoPlayerController _controller;
  String videoUrl = ''; // To store the determined video URL

  @override
  void initState() {
    super.initState();
    int _posenumber;
    if (global.posenumber >= 24)
      _posenumber = global.posenumber - 24;
    else
      _posenumber = global.posenumber;

    // Simplified video URL determination
    videoUrl =
        'https://raw.githubusercontent.com/hpds-lab/rehab_video/main/pose_videos/${_posenumber}.mp4';
    // Fallback for specific numbers if the pattern doesn't hold (example)
    if (_posenumber == 0) {
      // Example: if video 0 is named differently or has a specific URL
      videoUrl =
          'https://raw.githubusercontent.com/hpds-lab/rehab_video/main/pose_videos/0.mp4';
    }
    // Add other specific cases if needed, otherwise the generic URL pattern is used.

    _controller = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    // Adjusted buttonSize for landscape to ensure they fit well when stacked vertically.
    final buttonSize =
        isLandscape ? screenSize.height * 0.14 : screenSize.width * 0.2;
    final buttonIconSize = buttonSize * 0.6;
    // Adjusted instructionFontSize for landscape to better fit the side panel.
    final instructionFontSize =
        isLandscape ? screenSize.height * 0.03 : screenSize.width * 0.05;
    final appBarButtonSize = isLandscape
        ? screenSize.height * 0.08
        : screenSize.width * 0.1; // For potential AppBar elements

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
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : Center(child: CircularProgressIndicator()),
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => pose_view()),
                      );
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
      // Portrait layout (original structure)
      bodyContent = Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_controller.value.isInitialized)
                Container(
                  width: double.infinity, // Portrait takes full width
                  child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller)),
                )
              else
                CircularProgressIndicator(),
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => pose_view()),
                      );
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
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 144, 189, 249),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Colors.white, size: appBarButtonSize * 0.7),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("動作示範",
            style: TextStyle(
                color: Colors.white,
                fontSize: isLandscape
                    ? screenSize.height * 0.05
                    : screenSize.width * 0.055)),
        centerTitle: true,
      ),
      body: Container(
        color: Color.fromARGB(255, 144, 189, 249),
        padding: EdgeInsets.all(
            isLandscape ? screenSize.width * 0.025 : 16.0), // Adjusted padding
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
