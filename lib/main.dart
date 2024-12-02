import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AR Video Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ARScreen(),
    );
  }
}

class ARScreen extends StatefulWidget {
  const ARScreen({super.key});

  @override
  _ARScreenState createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  late List<Map<String, String>> imagesAndVideos;
  VideoPlayerController? videoController;
  bool isVideoPlaying = false;
  String currentImageUrl = "";

  @override
  void initState() {
    super.initState();
    imagesAndVideos = [];
    fetchImagesAndVideos();
  }

  // Fetch images and videos from the API
 Future<void> fetchImagesAndVideos() async {
  // تصاویر و ویدیوها به صورت دستی
  setState(() {
    imagesAndVideos = [
      {
        'image': 'https://www.w3schools.com/w3images/lights.jpg',
        'video': 'https://www.w3schools.com/html/mov_bbb.mp4',
      },
      {
        'image': 'https://www.w3schools.com/w3images/fjords.jpg',
        'video': 'https://www.w3schools.com/html/movie.mp4',
      },
      {
        'image': 'https://www.w3schools.com/w3images/mountains.jpg',
        'video': 'https://www.w3schools.com/html/mov_bbb.mp4',
      },
    ];
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Video Demo'),
      ),
      body: arSessionManager == null || arObjectManager == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ARView(
                  onARViewCreated: onARViewCreated,
                  onARFrameUpdate: onARFrameUpdate,
                ),
              ],
            ),
    );
  }

  // ARView creation and setup
  void onARViewCreated(ARSessionManager sessionManager, ARObjectManager objectManager) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;

    arSessionManager?.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      handleTaps: false, // No need for taps to trigger actions
    );
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    videoController?.dispose();
    super.dispose();
  }

  // Handle AR frame updates and detect image in the AR space
  void onARFrameUpdate(ARFrame frame) {
    for (var anchor in frame.anchors) {
      if (anchor is ARImageAnchor) {
        _handleImageDetection(anchor);
      }
    }
  }

  // Handle image detection and play video
  void _handleImageDetection(ARImageAnchor anchor) {
    String detectedImageUrl = anchor.name;  // The name can be the image URL or ID
    
    if (currentImageUrl != detectedImageUrl) {
      setState(() {
        currentImageUrl = detectedImageUrl;
        isVideoPlaying = false;  // Stop any current video
      });

      // Load and play video for this image
      _loadAndPlayVideo(detectedImageUrl, anchor);
    }
  }

  // Load and play video based on the image URL
  void _loadAndPlayVideo(String imageUrl, ARImageAnchor anchor) {
    String videoUrl = imagesAndVideos.firstWhere((image) => image['image'] == imageUrl)['video']!;
    
    videoController = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {
          isVideoPlaying = true;
        });

        // Create AR Video Node
        final arVideoNode = ARVideoNode(
          videoPlayerController: videoController!,
        );

        // Set the AR Video Node's position relative to the detected image
        arSessionManager?.addNodeWithAnchor(
          arVideoNode,
          anchor,
        );

        videoController?.play();
      }).catchError((e) {
        print('Error playing video: $e');
        // Handle error playing video (e.g., show a message to the user)
      });
  }
}
