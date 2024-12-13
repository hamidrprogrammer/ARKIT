// main.dart
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vector_math/vector_math_64.dart';  // Add this line

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZauberMoment',
      home: ImageVideoListScreen(),
    );
  }
}

class ImageVideoListScreen extends StatefulWidget {
  @override
  _ImageVideoListScreenState createState() => _ImageVideoListScreenState();
}

class _ImageVideoListScreenState extends State<ImageVideoListScreen> {
  List<Map<String, String>> mediaList = [
    {
      "image": "https://example.com/sample_image_1.png",
      "video": "https://example.com/sample_video_1.mp4"
    },
    {
      "image": "https://example.com/sample_image_2.jpg",
      "video": "https://example.com/sample_video_2.mp4"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image & Video List')),
      body: ListView.builder(
        itemCount: mediaList.length,
        itemBuilder: (context, index) {
          final media = mediaList[index];
          return ListTile(
            leading: Image.network(media["image"]!),
            title: Text('Media ${index + 1}'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ARVideoPlayer(
                  imageUrl: media["image"]!,
                  videoUrl: media["video"]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ARVideoPlayer extends StatefulWidget {
  final String imageUrl;
  final String videoUrl;

  ARVideoPlayer({required this.imageUrl, required this.videoUrl});

  @override
  _ARVideoPlayerState createState() => _ARVideoPlayerState();
}

class _ARVideoPlayerState extends State<ARVideoPlayer> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late VideoPlayerController videoController;
  bool isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    videoController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    arSessionManager.dispose();
    videoController.dispose();
    super.dispose();
  }

  // Ensure this method matches the ARViewCreatedCallback signature
  void onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager)
  {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;

    arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: true,
    );

    arObjectManager.onInitialize();
    addARImage(widget.imageUrl);
  }

  Future<void> addARImage(String imageUrl) async {
    final imageBytes = await http.get(Uri.parse(imageUrl));
    final imageNode = ARNode(
      type: NodeType.localGLTF2,
      uri: "localImage.gltf",
      scale: Vector3(0.5, 0.5, 0.5),
      position: Vector3(0.0, 0.0, -1.0),
    );

    await arObjectManager.addNode(imageNode);
  }

  void toggleVideoPlayback() {
    setState(() {
      isVideoPlaying = !isVideoPlaying;
      isVideoPlaying ? videoController.play() : videoController.pause();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AR Video Player')),
      body: Stack(
        children: [
          // Ensure `onARViewCreated` matches the expected callback type
          ARView(onARViewCreated: onARViewCreated),
          if (videoController.value.isInitialized)
            Positioned(
              bottom: 20,
              left: 20,
              child: GestureDetector(
                onTap: toggleVideoPlayback,
                child: Container(
                  width: 200,
                  height: 200,
                  child: VideoPlayer(videoController),
                ),
              ),
            )
        ],
      ),
    );
  }
}